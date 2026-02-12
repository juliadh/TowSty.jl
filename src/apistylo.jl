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
    getworkspace(id::String, apikey::String; backup::Bool=false) -> Dict

Fetch a workspace from the Stylo API and save it to disk.
If `backup` is true, creates a backup of the existing workspace.json before updating.

* `id::String`: The workspace ID to retrieve
* `apikey::String`: The API key for authentication
* `backup::Bool`: Whether to create a backup before updating (default: false)

### Example

```julia
# Initial setup
workspace = getworkspace("workspaceid", "styloapikey")

# Update with backup
workspace = getworkspace("workspaceid", "styloapikey", backup=true)
```
"""
function getworkspace(workspaceid, apikey; backup::Bool=false)
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

  # Create backup if requested
  if backup
    backupworkspace()
  end

  try
    response = GraphQLClient.execute( styloclient(apikey), query )
    data = response.data["workspace"]
    write(DATA_PATH, JSON.json(data))
    @info "Workspace data updated successfully"
    return data
  catch e
    @error "Failed to fetch or save workspace" exception=e
    if backup
      @warn "Attempting to restore from backup..."
      if restoreworkspace()
        @info "Workspace restored from backup"
      end
    end
    rethrow(e)
  end
end
