--Displaying details in imported excel

SELECT *
FROM PortfolioProject..CovidDeaths
where continent is not null
ORDER BY 3, 4


SELECT *
FROM PortfolioProject..CovidVaccin
where continent is not null
ORDER BY 3, 4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where continent is not null
ORDER BY 1, 2


--select total_cases
--from PortfolioProject..CovidDeaths
--where continent is not null
--WHERE ISNUMERIC(total_cases) <> 1;


--Checking the Death Percentage for African Countries

SELECT LOCATION, DATE, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where location like '%Africa%' AND continent IS NOT NULL
order by 1,2



--Displaying the Maximum casas and Maximum death in African Countries

SELECT MAX(total_cases) as max_total_case, MAX(total_deaths) as max_total_death
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Africa%' AND continent IS NOT NULL

--OR


SELECT MAX(total_cases) as max_total_case, MAX(total_deaths) as max_total_death
FROM PortfolioProject..CovidDeaths
WHERE CovidDeaths.location LIKE '%Africa%' AND CovidDeaths.continent IS NOT NULL



--Checking the rate of population affected in Africa


SELECT LOCATION, DATE, total_cases, population, (CAST(total_cases AS float) / population)*100 as Affected_Population_percentage
FROM PortfolioProject..CovidDeaths
where location like '%Africa%' AND continent IS NOT NULL
order by 1,2


--The Higest affected population percentage in africa

SELECT LOCATION, population, MAX(total_cases) as HigestCaseCount, MAX(CAST(total_cases AS float) / population)*100 as MAX_Affected_Population_percentage
FROM PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by MAX_Affected_Population_percentage desc


--This is showing the coutries with the highest Death Count per population


SELECT LOCATION, population, MAX(total_deaths) as HigestDeathCount, MAX(CAST(total_deaths AS float) / population)*100 as MAX_Death_Population_percentage
FROM PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by MAX_Death_Population_percentage desc


--same caculation and arrangement by Death rate

SELECT LOCATION, population, MAX(CAST(total_deaths AS INT)) as HigestDeathCount, MAX(CAST(total_deaths AS INT) / population)*100 as MAX_Death_Population_percentage
FROM PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by HigestDeathCount desc



--LET'S BREAK THINGS DOWN BY CONTINENT

 --Showing the continent with the highest death rate per population

SELECT continent, MAX(CAST(total_deaths AS INT)) as HigestDeathCount, MAX(CAST(total_deaths AS INT) / population)*100 as MAX_Death_Population_percentage
FROM PortfolioProject..CovidDeaths
where continent is NOT null
group by continent
order by HigestDeathCount desc



--Let's have some world review



SELECT date, 
  SUM(new_cases) as Daily_New_Cases, 
  SUM(new_deaths) as Daily_New_Deaths, 
  SUM(new_deaths) / NULLIF(SUM(new_cases), 0) as Case_Fatality_Ratio
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


--OR


SELECT date, 
  SUM(new_cases) as Daily_New_Cases, 
  SUM(new_deaths) as Daily_New_Deaths, 
  CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE SUM(new_deaths)/SUM(new_cases)*100 END as Case_Fatality_Ratio
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


--CHECKING TOTAL CASES, TOTAL DEATHS AND CASE FATALITY RATIO WORLDWIDE



SELECT --date, 
  SUM(new_cases) as Daily_New_Cases, 
  SUM(CAST(new_deaths as int)) as Daily_New_Deaths, 
  CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE SUM(CAST(new_deaths as int))/SUM(new_cases)*100 END as Case_Fatality_Ratio
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2



--Joining both tables


select*
from PortfolioProject..CovidDeaths  dea
join PortfolioProject..CovidVaccin  vac
     on dea.location = vac.location
     and dea.date = vac.date


--lets look at total population vs vaccine


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as Total_vaccination_at_date
from PortfolioProject..CovidDeaths  dea
join PortfolioProject..CovidVaccin  vac
     on dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3



--USING A CTE TO FIND OUT THE PERCENTAGE OF POPULATION VACCINATED

WITH PopvsVac (Continent, Date, Location, Population, New_vacinnation, Total_vaccination_at_date)
as

(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as Total_vaccination_at_date
from PortfolioProject..CovidDeaths  dea
join PortfolioProject..CovidVaccin  vac
     on dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3
)
select *, (Total_vaccination_at_date/Population)*100 as PopulationPercentageVaccinated
from PopvsVac


--let's derive the same result using temp teble

DROP table if exists #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinate numeric,
Total_vaccination_date numeric,
)

insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths  dea
join PortfolioProject..CovidVaccin  vac
     on dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3

SELECT *, (CAST(Total_vaccination_date as bigint)/Population)*100
FROM #PercentagePopulationVaccinated



--creating view


create view PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths  dea
join PortfolioProject..CovidVaccin  vac
     on dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent IS NOT NULL


DROP VIEW PercentagePopulationVaccinated;
