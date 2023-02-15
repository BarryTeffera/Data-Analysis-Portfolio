--SELECT *
--FROM Covid_Project..CovidDeaths Order by 3,4;

--SELECT *
--FROM Covid_Project..CovidVaccinations Order by 3,4;

-- Select data we're gonna use

Select location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Project..CovidDeaths Order by 1,2;

-- Looking at total cases vs total deaths
-- Shows likelihood of dying from covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Covid_Project..CovidDeaths 
WHERE location like '%states%'
Order by 1,2;

-- Looking at total cases vs population
Select location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
FROM Covid_Project..CovidDeaths 
WHERE location like '%states%'
Order by 1,2;

--Looking at countries with the highest infection rate compared to population
Select location, population, max(total_cases) HighestInfectionCount, max((total_cases/population))*100 as InfectionPercentage
FROM Covid_Project..CovidDeaths 
--WHERE location like '%states%'
Group By Location, population
Order by InfectionPercentage DESC;

-- Showing countries with the highest death count
	Select location, max(cast(total_deaths as int)) as TotalDeathCount
	FROM Covid_Project..CovidDeaths 
	--WHERE location like '%states%'
	WHERE continent is not null
	Group By Location 
	Order by TotalDeathCount DESC;

	-- Let's group things by Continent
	Select location, max(cast(total_deaths as int)) as TotalDeathCount
	FROM Covid_Project..CovidDeaths 
	--WHERE location like '%states%'
	WHERE continent is null
	Group By location 
	Order by TotalDeathCount DESC;

	Select continent, max(cast(total_deaths as int)) as TotalDeathCount
	FROM Covid_Project..CovidDeaths 
	--WHERE location like '%states%'
	WHERE continent is not null
	Group By continent 
	Order by TotalDeathCount DESC;

	--Showing Continents with the highest death count
	Select location, max(cast(total_deaths as int)) as TotalDeathCount
	FROM Covid_Project..CovidDeaths 
	--WHERE location like '%states%'
	WHERE continent is null
	Group By location 
	Order by TotalDeathCount DESC;

	--Global numbers
Select date, sum(new_cases)
FROM Covid_Project..CovidDeaths 
--WHERE location like '%states%'
WHERE continent is not null
Group By date
Order by 1,2;

Select date, sum(new_cases) as new_cases, sum(cast(new_deaths as int)) as new_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM Covid_Project..CovidDeaths 
--WHERE location like '%states%'
WHERE continent is not null
Group By date
Order by 1,2;

Select * 
From Covid_Project..covidvaccinations

-- Looking at total population vs vaccination

Select * From Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date;

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3;

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

--CTE strategy

WITH PopvsVac (Continent, Location, date, Population, new_vaccinations, RollingPplVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPplVaccinated/Population)*100 as RollingPercentOfPplVaccinated
FROM PopvsVac

--Temp Table strategy
--Drop table if exists #PercentPopulationVaccinated uncomment to edit temp table

Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
new_vaccinations numeric, 
RollingPplVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
SELECT *, (RollingPplVaccinated/Population)*100 as RollingPercentOfPplVaccinated
FROM #PercentPopulationVaccinated

--Creating view to store data for late visualizations
 CREATE VIEW PercentPopulationVaccinated as
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM Covid_Project..CovidDeaths dea
Join Covid_Project..covidvaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
WHERE dea.continent is not null

Select *
FROM PercentPopulationVaccinated