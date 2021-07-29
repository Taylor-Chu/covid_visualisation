-- SELECT *
-- FROM covid_analysis..CovidDeaths
-- order by 3,4

-- select the data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population FROM covid_analysis..CovidDeaths
order by 1,2

-- Total Cases vs Total Deaths
-- shows the likelihood of death if one contracted covid in a country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM covid_analysis..CovidDeaths
WHERE Location='United States'
ORDER BY Location, date

-- Total Cases vs Population
SELECT Location, date, total_cases, population, (total_cases/population)*100 as ContractionPercentage 
FROM covid_analysis..CovidDeaths
WHERE Location='United States'
ORDER BY Location, date


-- looking at country with highest infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PercentPopulationInfected 
FROM covid_analysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- looking at country with highest death rate compared to population
SELECT location, MAX(total_deaths) as HighestDeathCount, population, MAX((total_deaths/population))*100 as PercentPopulationDeath
FROM covid_analysis..CovidDeaths
WHERE continent IS NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC

-- looking at country with highest death count
SELECT continent, location, CAST(MAX(total_deaths) AS INT) as totalDeathCount
FROM covid_analysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY totalDeathCount DESC

-- looking at continents with highest death count
SELECT location, CAST(MAX(total_deaths) AS INT) as totalDeathCount
FROM covid_analysis..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY totalDeathCount DESC


-- global
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage 
FROM covid_analysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY TotalCases DESC


-- looking at total population vs vaccinations

-- use cte
WITH PopVsVac (continent, location, date, population,new_vaccinations, RollingTotalVaccinations) 
as
(
SELECT cd.continent, CAST(cd.location as varchar(30)) as location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations as int)) OVER (PARTITION BY CAST(cd.location as varchar(30)) ORDER BY CAST(cd.location as varchar(30)), cd.date) as RollingTotalVaccinations
FROM covid_analysis..CovidDeaths            cd
JOIN covid_analysis..CovidVaccinations      cv
ON (cd.location=cv.location) and (cd.date=cv.date)
-- GROUP BY cd.continent, cd.location
WHERE cd.continent is not NULL
-- ORDER BY continent, cd.location
)
SELECT *, RollingTotalVaccinations/population*100 as PercentVaccinated FROM PopVsVac
ORDER BY continent, location


-- temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255), 
    location nvarchar(255),
    date datetime, 
    population NUMERIC, 
    new_vaccinations NUMERIC, 
    RollingTotalVaccinations NUMERIC
)
INSERT into #PercentPopulationVaccinated
SELECT cd.continent, CAST(cd.location as varchar(30)) as location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations as int)) OVER (PARTITION BY CAST(cd.location as varchar(30)) ORDER BY CAST(cd.location as varchar(30)), cd.date) as RollingTotalVaccinations
FROM covid_analysis..CovidDeaths            cd
JOIN covid_analysis..CovidVaccinations      cv
ON (cd.location=cv.location) and (cd.date=cv.date)
-- GROUP BY cd.continent, cd.location
WHERE cd.continent is not NULL
-- ORDER BY continent, cd.location

SELECT *, RollingTotalVaccinations/population*100 as PercentVaccinated FROM #PercentPopulationVaccinated
ORDER BY continent, location

-- total vaccinations by country
SELECT cd.continent, cd.location, MAX(cd.population) as population, MAX(cv.total_vaccinations) as TotalVaccinations,
    MAX(cv.total_vaccinations)/MAX(cd.population)*100 as PercentVaccinations
FROM covid_analysis..CovidDeaths        cd
JOIN covid_analysis..CovidVaccinations  cv
ON cd.location=cv.location
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, cd.continent
ORDER BY continent, location

-- creating view to store data for later visualisation
CREATE VIEW VaccinationRateByCountry AS
SELECT cd.continent, cd.location, MAX(cd.population) as population, MAX(cv.total_vaccinations) as TotalVaccinations, MAX(cv.total_vaccinations)/MAX(cd.population)*100 as PercentVaccinations
FROM covid_analysis..CovidDeaths        cd
JOIN covid_analysis..CovidVaccinations  cv
ON cd.location=cv.location
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, cd.continent
-- ORDER BY continent, location


SELECT location from VaccinationRateByCountry

