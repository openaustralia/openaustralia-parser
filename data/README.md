# Hand-made data

This directory contains hand-made data. It was more straightforward to build this by hand than to write a parser.

- `members.csv`  
    Contains members of the House of Representatives and the Senate since 1980. This data was originally compiled from the 41st Parliamentary Handbook. The House of Representatives data was taken from [41st Parliamentary Handbook — Representatives](http://www.aph.gov.au/library/handbook41st/historical/representatives/index.htm). The data was manually updated to take into account the 2007 general elections. Senator information was taken from [41st Parliamentary Handbook — Senate](http://www.aph.gov.au/library/handbook41st/historical/senate/index.htm).

- `ministers.csv`  
    Contains the periods when particular people were ministers. The data was originally taken from [Howard ministries (41st Parliamentary Handbook)](http://www.aph.gov.au/library/handbook41st/historical/ministries/59.howard.htm).

- `shadow-ministers.csv`  
    Contains the periods when particular people were part of the shadow ministry. Current as of May 2008 and goes back to 20 March 1996.

- `postcodes.csv`  
    From the Australian Bureau of Statistics: [abs.gov.au](http://www.abs.gov.au/).

- `people.csv`  
    The `aph_id` field is the ID for the person assigned by the aph.gov.au website. This is used when looking up members in the Hansard. To find the `aph_id` for, for example, Tony Abbott, go to Parlinfo Search ([http://parlinfo.aph.gov.au/](http://parlinfo.aph.gov.au/)) and search for the term `tony abbott Dataset:members,allmps`. It should return two results. Look at the IDs of the documents; they will be of the form `handbook/members/<ID>` or `handbook/allmps/<ID>`. The last part is the `aph_id`.

- `patches/`  
    Contains patches for the Hansard XML files to fix errors by hand that are too painful or ugly to fix automatically.
