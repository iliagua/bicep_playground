#Login
`az login --tenant {id}`

#Deploy
```
az bicep build -f .\main.bicep
az deployment group create --resource-group ilya-test --template-file .\main.json
az deployment group delete
```