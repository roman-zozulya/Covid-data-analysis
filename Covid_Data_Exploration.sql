SELECT top 500 *
FROM ['covid_deaths']
--WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT top 500 *
FROM ['covid_vaccinations']
ORDER BY 3,4;


-- Select Data that we are going to be using
SELECT [location], 
    [date], 
    total_cases, 
    new_cases, 
    total_deaths, 
    [population]
FROM ['covid_deaths']
WHERE continent is not NULL
ORDER BY 1,2;


-- Look at Toatl cases vs Toatal Deaths
-- shows likelihood (by day) of dying if you contract covid in your country
SELECT [location], 
    [date], 
    total_cases, 
    total_deaths, 
    (total_deaths / total_cases) * 100 as death_percentage
FROM ['covid_deaths']
WHERE LOWER([location]) = 'australia'
    AND continent is not NULL
ORDER BY 1,2;



-- Looking the Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT [location], 
    [date], 
    [population],
    total_cases,  
    (total_cases / [population]) * 100 as death_percentage
FROM ['covid_deaths']
WHERE LOWER([location]) = 'australia'
    AND continent IS NOT NULL
ORDER BY 1,2;



-- Looking at countries with highest Infection Rate compared to population

SELECT [location], 
    [population], 
    MAX(total_cases) as highest_infection_count, 
    MAX((total_cases / [population]) * 100) as percent_population_infected
FROM ['covid_deaths']
WHERE continent IS NOT NULL
GROUP BY [location], [population]
ORDER BY percent_population_infected DESC;



-- Showing Countries with Highest Death Count per Population

SELECT [location], 
    MAX(CAST(total_deaths as int)) as total_deaths_count
FROM ['covid_deaths']
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY total_deaths_count DESC;





-- Break down by continent
-- the numbers by continents are not correct using the "continent" field
-- the "location" field contains continents as well and this numbers are more correct, so we will be using continents from "location" field
-- also "location field" contains income level instead of name of the continent, we will get rid this from result
SELECT [location], 
    MAX(CAST(total_deaths as int)) as total_deaths_count
FROM ['covid_deaths']
WHERE continent IS NULL
GROUP BY [location]
ORDER BY total_deaths_count DESC;



-- global numbers

SELECT [date], 
    SUM(new_cases) as new_cases_count, 
    SUM(CAST(new_deaths as int)) as total_deaths_count, 
    SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 as death_percentage
FROM ['covid_deaths']
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1,2;

-- global numbers generally
SELECT
    SUM(new_cases) as new_cases_count, 
    SUM(CAST(new_deaths as int)) as total_deaths_count, 
    SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 as death_percentage
FROM ['covid_deaths']
WHERE continent IS NOT NULL



-- Looking at Total Population vs Vaccinations

WITH population_vs_vaccinations AS -- using CTE to get Rolling People Vaccinated Percentage
    (SELECT dea.[continent], 
        dea.[location], 
        dea.[date], 
        dea.population, 
        vac.new_vaccinations, 
        SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
        -- converting "new_vaccinations" into biging because this number is over ~2.1 billion and out of integet range
    FROM ['covid_deaths'] dea 
        JOIN ['covid_vaccinations'] vac 
        ON dea.[location] = vac.[location]
        AND dea.[date] = vac.[date]
    WHERE dea.continent IS NOT NULL)
SELECT *, 
    (rolling_people_vaccinated / population) * 100 as rolling_people_vaccineted_perc
FROM population_vs_vaccinations;



-- TEMP TABLE

DROP TABLE if EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
    continent NVARCHAR(255), 
    [location] NVARCHAR(255), 
    [date] DATETIME, 
    [population] NUMERIC, 
    new_vaccinations NUMERIC, 
    rolling_people_vaccinated NUMERIC 
)

INSERT into #percent_population_vaccinated
SELECT dea.[continent], 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM ['covid_deaths'] dea 
    JOIN ['covid_vaccinations'] vac 
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL

SELECT *, 
    (rolling_people_vaccinated / [population]) * 100
FROM #percent_population_vaccinated
ORDER BY 2,3



-- Creating view to store data for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.[continent], 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM ['covid_deaths'] dea 
    JOIN ['covid_vaccinations'] vac 
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL



