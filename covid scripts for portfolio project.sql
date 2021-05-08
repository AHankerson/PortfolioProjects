/****** Script for SelectTopNRows command from SSMS  ******/
 SELECT TOP 1000 * from [dbo].[covidDeaths$]
 where location = 'Andorra'
 order by location, date
 

-- SELECT TOP 5 * from [dbo].[covidVaccinations$]
-- order by location, date

-- Look at data that we will be using
select 
    location, 
    date,
    total_cases, 
    new_cases, 
    total_deaths, 
    population
from [dbo].[covidDeaths$]
order by location, date

-- Total cases vs Total Deaths
select 
    location, 
    date,
    total_cases, 
    total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
from [dbo].[covidDeaths$]
order by location, date

-- Total cases vs Total Deaths in the US
-- At the end of 2020 we had 20099363 cases and 352123 deaths
select 
    location, 
    date,
    total_cases, 
    total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
from [dbo].[covidDeaths$]
where location like '%States'
order by location, date

-- Total cases vs population
-- Shows what percentage of poulation got Covid
select 
    location, 
    date,
	population,
    total_cases,	
	total_cases/population*100 as InfectionPercentage  	
from [dbo].[covidDeaths$]
where location like '%States'
order by location, date

-- Countries with highest infection rate compared to population
select 
    location, 
    population,
    max(total_cases) as HighestInfectionCount,	
	max((total_cases/population)*100) as PopInfectionPercentage	
from [dbo].[covidDeaths$]
group by population, location
order by PopInfectionPercentage desc


-- Countries with Highest Deaths
select 
    location,     
    MAX(cast(total_deaths as int)) AS total_deaths		
FROM [dbo].[covidDeaths$]
--where continent is not null
group by location
order by total_deaths desc


-- Countries with Highest Death Count per Pop
select 
    location, 
    population,
    max(total_deaths) as TotalDeaths,	
	max((total_deaths/population)*100) as DeathPercByPop,
	(max(total_deaths)/population)*100 as DeathPercByPop1
from [dbo].[covidDeaths$]
group by population, location
order by DeathPercByPop desc

----------------------LETS'S BREAK THINGS DOWN BY CONTINENT-------------------------------

select 
    location,     
    MAX(cast(total_deaths as int)) AS total_deaths		
FROM [dbo].[covidDeaths$]
where continent is null
group by location
order by total_deaths desc

--Showing continents with the highest death count per pop
select 
    continent,     
    MAX(cast(total_deaths as int)) AS total_deaths		
FROM [dbo].[covidDeaths$]
where continent is not null
group by continent
order by total_deaths desc

-- Global numbers
select     
    date,
    sum(new_cases), 
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int)) / sum(new_cases) * 100 as DeathPerc
from [dbo].[covidDeaths$]
where continent is not null
group by date
order by 1,2


select     
    sum(new_cases) total_cases, 
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int)) / sum(new_cases) * 100 as DeathPerc
from [dbo].[covidDeaths$]
where continent is not null
--group by date
order by 1,2

-- Join both tables
SELECT * from [dbo].[covidDeaths$] d
JOIN [dbo].[covidVaccinations$] v
 ON d.location = v.location
  AND d.date = v.date
 
-- Total population vs vaccinations
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVacCount
FROM [dbo].[covidDeaths$] d
JOIN [dbo].[covidVaccinations$] v
 ON d.location = v.location
  AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3


-- Use CTE
WITH PopVsVac AS 
(
	SELECT 
		d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVacCount
	FROM [dbo].[covidDeaths$] d
	JOIN [dbo].[covidVaccinations$] v
	 ON d.location = v.location
	  AND d.date = v.date
	WHERE d.continent IS NOT NULL
	--ORDER BY 2,3
)

SELECT *, (RollingVacCount/population)*100
FROM PopVsVac



-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVacCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
		d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVacCount
	FROM [dbo].[covidDeaths$] d
	JOIN [dbo].[covidVaccinations$] v
	 ON d.location = v.location
	  AND d.date = v.date
	WHERE d.continent IS NOT NULL
	--ORDER BY 2,3

SELECT
	*, (RollingVacCount/population)*100
FROM #PercentPopulationVaccinated


-- Create view for Visualization

create view PercentPopulationVaccinated as
SELECT 
		d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVacCount
	FROM [dbo].[covidDeaths$] d
	JOIN [dbo].[covidVaccinations$] v
	 ON d.location = v.location
	  AND d.date = v.date
	WHERE d.continent IS NOT NULL
	--ORDER BY 2,3

select * from PercentPopulationVaccinated