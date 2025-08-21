# Nimletter CSV Contact Importer

A command-line utility for bulk importing contacts from CSV files into Nimletter mailing lists.

## Overview

This tool allows you to efficiently add multiple contacts to your Nimletter mailing lists by processing a CSV file containing contact information. It handles both new contact creation and adding existing contacts to specific lists.

## Requirements

- Nim compiler (version 1.6.18+)
- CSV file with `email` and `name` columns
- Nimletter instance endpoint URL
- Valid API bearer token
- Target mailing list ID

## CSV Format

Your CSV file must contain the following columns:

```csv
email,name
john@example.com,John Doe
jane@example.com,Jane Smith
```

**Note**: Both `email` and `name` fields are required. Rows with missing data will be skipped.

## Usage

```bash
nim c -d:ssl -d:release add_contacts_from_csv.nim
./add_contacts_from_csv <csv_file> <endpoint> <bearer_token> <list_id>
```

### Parameters

- `csv_file`: Path to your CSV file
- `endpoint`: Base URL of your Nimletter instance (e.g., `https://nimletter.mailer.com`)
- `bearer_token`: Your Nimletter API key
- `list_id`: ID of the target mailing list

### Example

```bash
./add_contacts_from_csv mylist.csv https://nimletter.mailer.com 2d45f559-f50c-4e39-8e93-24f50b742732 my-list-id
```

## How It Works

1. **CSV Parsing**: Reads and validates the CSV file, extracting email and name data
2. **Contact Verification**: Checks if each contact already exists in the system
3. **Smart Processing**:
   - For existing contacts: Adds them to the specified list
   - For new contacts: Creates the contact and adds them to the list
4. **Progress Tracking**: Provides real-time feedback on each operation
5. **Summary Report**: Displays final counts of processed contacts

## Notes

- The tool processes contacts sequentially to avoid overwhelming the API
- Double opt-in is disabled by default for bulk imports
- All contacts are assigned to flow step 1
- The tool will exit if the CSV file cannot be parsed or if confirmation is denied

## Troubleshooting

- **CSV Format Issues**: Ensure your CSV has the correct column headers (`email`, `name`)
- **API Errors**: Verify your bearer token and endpoint URL are correct
