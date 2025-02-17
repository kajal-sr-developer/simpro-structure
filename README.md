# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover

## Background Jobs

The application uses ActiveJob with Delayed::Job for asynchronous processing. All jobs are queued as `:default`.



#### SimPro to HubSpot Sync
- `ProcessQuoteJob` - Syncs quotes from SimPro
- `ProcessContactJob` - Processes individual customer updates
- `ProcessCompanyJob` - Handles company updates
- `ProcessSiteJob` - Manages site synchronization
- `ProcessTicketJob` - Updates tickets from jobs

#### HubSpot to SimPro Sync
- `ProcessHubspotContactJob` - Creates/updates contacts in SimPro
- `ProcessHubspotCompanyJob` - Syncs companies to SimPro
- `ProcessHubspotQuoteJob` - Creates quotes in SimPro
- `ProcessHubspotSiteJob` - Manages site creation/updates


### SimPro Webhook Configuration

1. **Individual Customer Updates**
   - URL: `/simpro/individual_customer`
   - Method: POST
   - Payload: Contains `individualCustomerID`

2. **Company Updates**
   - URL: `/simpro/company_customer`
   - Method: POST
   - Payload: Contains `customerID`

3. **Quote Updates**
   - URL: `/simpro/quote`
   - Method: POST
   - Payload: Contains `quoteID`

### HubSpot Webhook Configuration

1. **Contact Updates**
   - URL: `/hubspot/contact_webhook`
   - Method: POST
   - Payload: Contains contact properties

2. **Company Updates**
   - URL: `/hubspot/company_webhook`
   - Method: POST
   - Payload: Contains company properties

3. **Deal Updates**
   - URL: `/hubspot/deal_notes_webhook`
   - Method: POST
   - Payload: Contains deal properties



### Authentication
- All webhooks require valid API tokens
- CSRF protection is disabled for webhook endpoints
- IP whitelist recommended for production

### Example Webhook Setup

Key background jobs:
- `ProcessQuoteJob` - Handle quote processing
- `ProcessContactJob` - Process contact updates
- `ProcessCompanyJob` - Handle company updates
- `ProcessSiteJob` - Process site changes

## Error Handling

### API Error Handling


### Development Setup

1. Create a `.env` file in the project root:

```

### Required Variables Checklist

- [ ] SIMPRO_LIVE_URL
- [ ] SIMPRO_LIVE_KEY_ID
- [ ] SIMPRO_LIVE_TOKEN
- [ ] HUBSPOT_API_KEY
- [ ] DEAL_TICKET_ASSOCIATION_ID
- [ ] DATABASE_URL
- [ ] SECRET_KEY_BASE
- [ ] RAILS_ENV

### Security Considerations

1. **Never commit sensitive values**
   - Use `.env.example` for documentation
   - Keep `.env` in `.gitignore`

2. **Production Security**
   - Use secure environment variable storage
   - Implement key rotation
   - Monitor for unauthorized access

3. **Access Control**
   - Limit access to environment variables
   - Log environment variable usage
   - Regular security audits

### Troubleshooting

Common environment issues:
1. Missing required variables
2. Invalid API keys
3. Expired tokens
4. Incorrect URL formats

Debug checklist:
- Verify all required variables are set
- Check variable naming
- Validate token expiration
- Confirm URL formatting

### Environment Variable Management

Best practices:
1. Document all variables
2. Use meaningful names
3. Group related variables
4. Implement validation
5. Regular audits

### Monitoring

Monitor for:
- Token expiration
- API rate limits
- Invalid credentials
- Configuration changes

### Development vs Production

Development:

```

# config/environments/development.rb
config.cache_classes = false
config.eager_load = false
```

Production:
```

# config/environments/production.rb
config.cache_classes = true
config.eager_load = true
```
# HubSpot Custom Objects Setup

This repository contains rake tasks for creating custom objects in HubSpot CRM. These tasks set up the necessary schema, properties, and groups for various business entities.

## Available Tasks

### 1. Cost Centers
Creates a custom object for Cost Centers with:
- Primary display property: `name`
- Properties group: `cost_center_information`
- Properties:
  - name
  - simpro_id

rake hubspot:create_cost_center

### 2. Jobs
Creates a custom object for Jobs with multiple property groups:
- job_information
- resources_cost
- gross_margin
- materials_cost
- sync_info

rake hubspot:create_job_object

Key properties include job details, costs, margins, and synchronization information.

### 3. Sites
Creates a custom object for Sites with:
- Primary display property: `site_name`
- Properties group: `site_information`
- Properties include:
  - site_name
  - country
  - postal details
  - primary contact information
  rake hubspot:create_site_object

## Setup

1. Ensure you have the required environment variables:

```bash
HUBSPOT_API_KEY=your_api_key
```

2. The tasks use HTTParty for API communication. Make sure it's included in your Gemfile:
```ruby
gem 'httparty'
```

## Usage

Each task can be run independently to create its respective custom object structure in HubSpot. The tasks handle:
- Custom object creation
- Property groups setup
- Individual properties creation with appropriate field types

## Note

- These tasks should typically be run only once during initial setup
- Running them multiple times may result in API errors if the objects already exist
- Make sure you have the necessary HubSpot API permissions
