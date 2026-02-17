"""
    styloclient(apikey::String)

Instantiate a GraphQL client.

# Argument
- `apikey::String`: The API key for authentication with Stylo

# Return
A configured GraphQL client for the Stylo API.
"""
function styloclient(apikey)
  endpoint = "https://stylo.huma-num.fr/graphql"
  headers = Dict( "Authorization" => apikey )

  return Client(endpoint, headers=headers)
end

"""
    getworkspace(id::String, apikey::String; backup::Bool=false)

Fetch a workspace from the Stylo API and writes it to `content/workspace.json`.
If `backup` is true, creates a backup of the existing `workspace.json` before updating.

# Arguments
- `id::String`: The workspace id to fetch
- `apikey::String`: The Stylo API key for authentication

# Keyword argument
- `backup::Bool`: Whether to create a backup before updating (default: false)

# Return
The workspace serialized as a Dict.
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
