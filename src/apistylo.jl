"""
    styloclient(apikey::String) -> Client

Create and return a GraphQL client configured for the Stylo API.

* `apikey::String`: The API key for authentication with Stylo
"""
function styloclient(apikey)
  endpoint = "https://stylo.huma-num.fr/graphql"
  headers = Dict( "Authorization" => apikey )

  return Client(endpoint, headers=headers)
end

"""
    getworkspace(id::String, apikey::String) -> Dict

Fetch a workspace from the Stylo API and save it to disk.

* `id::String`: The workspace ID to retrieve
* `apikey::String`: The API key for authentication

### Example

```julia
workspace = getworkspace("workspaceid", "styloapikey")
```
"""
function getworkspace(workspaceid, apikey)
  query = """
    query getWorkspace {
      workspace(workspaceId: "$(workspaceid)"){
        name
        description
        articles{
          _id
          title
          createdAt
          owner {
            displayName
            username
            email
          }
          contributors{
            user{ displayName }
          }
          workingVersion{
            md
            yaml
            bib
          }
        }
        corpus{
          _id
          name
          description
          metadata
          articles{
            article{
              _id
              title
              createdAt
              owner {
                displayName
                username
                email
              }
              contributors{
                user{ displayName }
              }
              workingVersion{
                md
                yaml
                bib
              }
            }
          }
        }
      }
    }
  """
  definepaths!()

  response = GraphQLClient.execute( styloclient(apikey), query )
  data = response.data["workspace"]
  write(DATA_PATH, JSON.json(data))
  return data
end
