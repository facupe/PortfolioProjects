-- Checking the data has been successfully uploaded
--select *
--from PortfolioProject..CovidVaccinations$
--order by 3,4
--select *
--from PortfolioProject..CovidDeaths$
--order by 3,4
-- Selecting data we're going to be using from now on
SELECT location
	,DATE
	,total_cases
	,new_cases
	,total_deaths
	,population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1
	,2



-- Looking at Total Cases vs Total Deaths
-- Percentage chance of dying if contracting COVID in Argentina

SELECT location
	,DATE
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%Argentina%'
ORDER BY 1
	,2



-- Looking at Total Cases vs Population
-- Displays what percentage of population got COVID

SELECT location
	,DATE
	,population
	,total_cases
	,total_deaths
	,(total_cases / population) * 100 AS InfectedRate
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%Argentina%'
ORDER BY 1
	,2



-- Looking at countries with highest infection rate compared to population

SELECT location
	,population
	,MAX(total_cases) AS HighestInfectionCount
	,(MAX(total_cases / population)) * 100 AS InfectedRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
GROUP BY location
	,population
ORDER BY InfectedRate DESC



-- Displaying countries with highest death count
-- total_deaths has been casted to int / Results as "world" and continents have been cleaned up from locations

SELECT location
	,MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Displaying continents with highest death count

SELECT location
	,MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Displaying countries with highest death rate by population

SELECT location
	,population
	,MAX(cast(total_deaths AS INT)) AS HighestDeathCount
	,(MAX(total_deaths / population)) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent IS NOT NULL
GROUP BY location
	,population
ORDER BY DeathRate DESC



-- Displaying continents with highest death rate by population

SELECT location
	,population
	,MAX(cast(total_deaths AS INT)) AS HighestDeathCount
	,(MAX(total_deaths / population)) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--where location like '%Argentina%'
WHERE continent IS NULL
	AND location != 'International'
	AND location != 'World'
GROUP BY location
	,population
ORDER BY DeathRate DESC



-- Global numbers per day

SELECT DATE
	,SUM(new_cases) AS total_cases
	,SUM(cast(new_deaths AS INT)) AS total_deaths
	,SUM(cast(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Argentina%'
WHERE continent IS NOT NULL
	AND total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
GROUP BY DATE
ORDER BY 1
	,2



-- Total global numbers (death rate)

SELECT /*date,*/ SUM(new_cases) AS total_cases
	,SUM(cast(new_deaths AS INT)) AS total_deaths
	,SUM(cast(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%Argentina%'
WHERE continent IS NOT NULL
	AND total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
--GROUP BY date
ORDER BY 1
	,2



-- Joining CovidVaccinations table

SELECT *
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE



-- Displaying total population vs vaccinations

SELECT dea.continent
	,dea.location
	,dea.DATE
	,dea.DATE
	,dea.population
	,vac.new_vaccinations
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
ORDER BY 2
	,3



-- Vacciantions rolling count per day

SELECT dea.continent
	,dea.location
	,dea.DATE
	,dea.population
	,vac.new_vaccinations
	,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.DATE
		) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
ORDER BY 2
	,3



-- Use CTE

WITH PopvsVac(continent, location, DATE, population, new_vaccinations, RollingPeopleVaccinated) AS (
		SELECT dea.continent
			,dea.location
			,dea.DATE
			,dea.population
			,vac.new_vaccinations
			,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
				PARTITION BY dea.location ORDER BY dea.location
					,dea.DATE
				) AS RollingPeopleVaccinated --, (RollingPeopleVaccinated/population)*100
		FROM PortfolioProject..CovidDeaths$ dea
		JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
			AND dea.DATE = vac.DATE
		WHERE dea.continent IS NOT NULL
		)
--ORDER BY 2,3
SELECT *
	,(rollingpeoplevaccinated / population) * 100 AS RollingPercentage
FROM PopvsVac



-- Temp table

DROP TABLE

IF EXISTS #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated (
		Continent NVARCHAR(255)
		,Location NVARCHAR(255)
		,DATE DATETIME
		,Population NUMERIC
		,New_vaccinations NUMERIC
		,RollingPeopleVaccinated NUMERIC
		)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
	,dea.location
	,dea.DATE
	,dea.population
	,vac.new_vaccinations
	,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location
			,dea.DATE
		) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
	AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
SELECT *
	,(rollingpeoplevaccinated / population) * 100 AS RollingPercentage
FROM #PercentPopulationVaccinated



-- Creating view to store data for later visualizations

	--CREATE VIEW PercentPopulationVaccinated AS
	--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations))
	--OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	--FROM PortfolioProject..CovidDeaths$ dea
	--JOIN PortfolioProject..CovidVaccinations$ vac
	--	ON dea.location = vac.location
	--	AND dea.date = vac.date
	--WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3