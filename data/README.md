# block-assignment

The `block-assignment` subdirectory includes official Census Bureau files showing which larger geography each census block was assigned to *at the time of the census*. The assignment files only include the numeric codes for each geography, so I also include the official name lookup tables, which contain the text labels for each numeric code. Both kinds of tables are included for the 2010 and 2020 decennial censuses.

The block assignment files can be downloaded through [this Census Bureau web interface](https://www.census.gov/geographies/reference-files/time-series/geo/block-assignment-files.html).

The name lookup files can be downloaded through [this Census Bureau web interface](https://www.census.gov/geographies/reference-files/time-series/geo/name-lookup-tables.2010.html#list-tab-2098172819).

I combine these files, add block population, and subset Milwaukee County in order to create `MilwaukeeCounty_Block_VTD_2010.csv` and `MilwaukeeCounty_Block_VTD_2020.csv`. See `SubsetMilwaukee.R` for code.

# block relationships

The file `tab2010_tab2020_st55_wi.txt` contains the official relationships (i.e. degree of overlap) between 2010 and 2020 census blocks. The file was downloaded from [this Census Bureau web page](https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.2020.html#list-tab-1709067297).

I add block population and subset Milwaukee County in order to create `MilwaukeeCounty_BlockRelationship_2010to2020.csv.csv`. See `SubsetMilwaukee.R` for code.

# ward-shp

The `ward-shp` subdirectory includes Milwaukee County ward boundaries for 2002, 2011, and 2022. These boundaries originated with the Wisconsin Technology Services Bureau (LTSB). I retrieved their archived files from the GeoData[@]Wisconsin archive, subset Milwaukee county, and converted to a standard coordinate reference system (4326) and file format (GeoJSON).

Here are stable links to the original source files:

* 2002: https://geodata.wisc.edu/catalog/7A9AD151-70BA-41F0-92D3-9CF396EEAFF3
* 2011: https://geodata.wisc.edu/catalog/WILTSB-fab48cb129b34f82b8afe66f872039200
* 2022: https://geodata.wisc.edu/catalog/WILTSB-4666354f85a246c5abcc3f6fa87744c50

# crosswalks

The `crosswalks` subdirectory includes files linking each vintage of blocks to wards.

* `Blocks2000_with_Ward2002.csv` includes the 2002 ward assignment for each block used in the 2020 census. It is constructed by intersecting the blocks with 2002 ward polygons. See `Build2000Crosswalk.R`.
* `Blocks2010_with_Ward2002_and_Ward2011.csv` includes the 2002 ward assignment *and* the 2011 ward assignment for each block used in the 2010 census. The 2002 ward assignments are taken from the "voting tabulation district (VTD)" field in the 2010 census. The names and numbers of wards from this VTD field match the names and numbers of wards from the 2002 LTSB shapefile. The 2011 ward assignments are constructed by intersecting the blocks with 2011 ward polygons. See `Build2010Crosswalk.R` for details.
* `Blocks2020_with_Ward2022_and_Ward2011.csv` includes the 2022 ward assignment *and* the 2011 ward assignment for each block used in the 2020 census. It was constructed in the same manner as the 2010 crosswalk. See `Build2020Crosswalk.R` for details.