# README for the `Tests` Folder

## Overview

This folder contains a collection of test scripts designed to ensure the integrity and correctness of the datasets and processing scripts used in the youth arrest data analysis project. These tests are essential for verifying the reliability of our data processing and analytical methods.

## Contents and Descriptions

### Test Scripts

1. **`downloadArrestDataTest.R`**
   - **Purpose**: Verifies that all expected arrest data files from the FBI's Crime Data API are successfully downloaded.
   - **Tests Included**:
     - File existence for each state and category.
     - File size checks to ensure each file is within the expected size limit.

2. **`processArrestDataTest.R`**
   - **Purpose**: Checks the processed arrest data for consistency and accuracy.
   - **Tests Included**:
     - Validation of proportion sums for a given state.
     - Data type and structure checks.
     - Verification of negative or NaN values in key columns.
     - Checks on data proportion bounds.
     - Validation of race category renaming.
     - Consistency checks for total counts within states.

3. **`getArrestPUMSTest.R`**
   - **Purpose**: Assesses the integrity of the PUMS data integration process.
   - **Tests Included**:
     - Data type and structure validation.
     - Checks for negative or NaN values in counts.
     - Verification of correct race category renaming.

4. **`finalizeArrestDataTest.R`**
   - **Purpose**: Ensures that the final distributed arrest data aligns with the processed data and maintains data integrity.
   - **Tests Included**:
     - Matching of total distributed arrests with total counts by state.
     - Verification of no negative or NaN values in distributed arrests.
     - Data types and structure validation.

## Usage

- To run these tests, ensure that all required data files are in the appropriate directories as specified in each test script.
- Execute each test script in R to perform the specified checks.
- Review the output of each test to confirm data integrity or to identify areas needing correction.

## Importance

- These tests are crucial for maintaining the quality and reliability of the analysis.
- Regular execution of these tests is recommended, especially after any data updates or changes to processing scripts.