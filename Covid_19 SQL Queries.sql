-- By analyzing the Total Deaths Vs. Total Cases,
-- shows the likelihood of dying from covid in your country

set nocount on;
begin
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
from reports.Covid_Deaths$
where Location = 'Lebanon'
order by 1,2;

-- Now looking at Total Cases Vs the Population
-- This is showing what percentage of population got Covid

select Location, date, total_cases, population, (total_cases/population)*100 as Death_Percentage
from reports.Covid_Deaths$
order by 1,2;

-- Countries with the highest infection rate compared to Population
select Location, max(total_cases) as Highest_Infection_count, population, max(total_cases/population)*100 as Percent_population_infected
from reports.Covid_Deaths$
group by Location, population
order by Percent_population_infected desc;

-- Continents with the Highest Death Count per Population
select continent, max(total_deaths) as Total_Death_Count
from reports.Covid_Deaths$
where continent is not null
group by continent
order by Total_Death_Count desc;
end

-- Global Statistics
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 
    END AS Death_Percentage
FROM reports.Covid_Deaths$
WHERE continent IS NOT NULL
ORDER by 1,2;

-- Total Population vs Vaccinations
select de.continent, de.location,de.date,de.population,va.new_vaccinations, sum(cast(isnull(va.new_vaccinations,0) as bigint)) over (Partition by de.location order by de.location,de.date) as cumulative_vaccinations
from reports.Covid_Deaths$ de
join reports.Covid_Vaccinations va
on de.location = va.location and de.date = va.date
where de.continent is not null
order by 2,3;

-- USING CTE
with popvsvac(continent,location,date,population,new_vaccinations,cumulative_vaccinations)
as
(
select de.continent, de.location,de.date,de.population,va.new_vaccinations, sum(cast(isnull(va.new_vaccinations,0) as bigint)) over (Partition by de.location order by de.location,de.date) as cumulative_vaccinations
from reports.Covid_Deaths$ de
join reports.Covid_Vaccinations va
on de.location = va.location and de.date = va.date
where de.continent is not null
)
select *, (cumulative_vaccinations/population)*100
from popvsvac;

-- A Temporary Table
drop table if exists #Percentpopulationvaccinated
Create table #Percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)
Insert into #Percentpopulationvaccinated
select de.continent, de.location,de.date,de.population,va.new_vaccinations, sum(cast(isnull(va.new_vaccinations,0) as bigint)) over (Partition by de.location order by de.location,de.date) as cumulative_vaccinations
from reports.Covid_Deaths$ de
join reports.Covid_Vaccinations va
on de.location = va.location and de.date = va.date
where de.continent is not null

select *, (cumulative_vaccinations/population)*100
from #Percentpopulationvaccinated;

-- Creating a view to store the data for later
create view Percentpopulationvaccinated as
select de.continent, de.location,de.date,de.population,va.new_vaccinations, sum(cast(isnull(va.new_vaccinations,0) as bigint)) over (Partition by de.location order by de.location,de.date) as cumulative_vaccinations
from reports.Covid_Deaths$ de
join reports.Covid_Vaccinations va
on de.location = va.location and de.date = va.date
where de.continent is not null;