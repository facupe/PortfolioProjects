-- Checking the data has been successfully uploaded

--select *
--from PortfolioProject..CovidVaccinations$
--order by 3,4

--select *
--from PortfolioProject..CovidDeaths$
--order by 3,4

-- Selecting data we're going to be using from now on

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1, 2



-- Looking at Total Cases vs Total Deaths
-- Percentage chance of dying if contracting COVID in Argentina

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
WHERE location like '%Argentina%'
ORDER BY 1, 2



-- Looking at Total Cases vs Population
-- Displays what percentage of population got COVID

SELECT location, date, population, total_cases, total_deaths, (total_cases/population)*100 AS InfectedRate
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%Argentina%'
ORDER BY 1, 2



-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases/population))*100 AS InfectedRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
GROUP BY location, population
ORDER BY InfectedRate desc


-- Displaying countries with highest death count
-- total_deaths has been casted to int / Results as "world" and continents have been cleaned up from locations

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Displaying continents with highest death count

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is null
GROUP by location
ORDER by TotalDeathCount desc



-- Displaying countries with highest death rate by population

SELECT location, population, MAX(cast(total_deaths as int)) AS HighestDeathCount, (MAX(total_deaths/population))*100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is not null
GROUP BY location, population
ORDER BY DeathRate DESC



-- Displaying continents with highest death rate by population

SELECT location, population, MAX(cast(total_deaths as int)) AS HighestDeathCount, (MAX(total_deaths/population))*100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is null AND location != 'International' AND location != 'World'
GROUP BY location, population
ORDER BY DeathRate DESC



-- Global numbers per day

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM
(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is not null AND total_cases is not null AND total_deaths is not null
GROUP BY date
ORDER BY 1, 2



-- Total global numbers (death rate)

SELECT /*date,*/ SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM
(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent is not null AND total_cases is not null AND total_deaths is not null
--group by date
ORDER BY 1, 2



-- Joining CovidVaccinations table

SELECT *
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date



-- Displaying total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



-- Vacciantions rolling count per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rollingpeoplevaccinated/population)*100 AS RollingPercentage
FROM PopvsVac



-- Temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (rollingpeoplevaccinated/population)*100 AS RollingPercentage
FROM #PercentPopulationVaccinated



-- Creating view to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations))
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3