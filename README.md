# SKR Azure modules

Här finns moduler som användas av SKR för att skapa resurser i Azure på ett standardiserat sätt.

## Förutsättningar

För att använda modulerna måste man ha tillgång till Azure, ha rätt behörighet och kunna kör Azure CLI kommandon. Man kan köra dem lokalt, en en container eller i Azure Cloud Shell.

### Exekvera en modul

För att skapa resurser måste man skapa en resursgrupp. Och sen skapar mallen alla resurser som behövs i resursgruppen.

    SITENAME=mysitename
    az group create --name $SITENAME --location northeurope

    az deployment group create --resource-group $SITENAME --template-file wordpress.bicep --name deploy_001 --parameters administratorLogin=<adminlogin> --parameters administratorLoginPassword=<adminpassword> --parameters siteName=$SITENAME

Dessa kommando skapar resursgruppen och alla resurser som behövs. Sen kan man konfguera den nya WordPress installationen.


