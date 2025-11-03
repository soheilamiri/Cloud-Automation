<#
.Synopsis
   Source an OpenStack OpenRC file.
.DESCRIPTION
   This script allows you to source an OpenRC file that can be downloaded from the 
   OpenStack dashboard. After running the script you'll be able to use the OpenStack 
   command-line tools. These need to be installed separately.
.PARAMETER LiteralPath
   The OpenRC file you downloaded from the OpenStack dashboard.
.EXAMPLE
   Source-OpenRC H:\project-openrc.sh
.LINK
   http://openstack.naturalis.nl
   https://www.linkedin.com/in/soheil-amiri-4bb785218/


#>

If ($args.count -lt 1) {
    Write-Host "Please provide an OpenRC file as argument."
    Exit
}

ElseIf ($args.count -gt 1) {
    Write-Host "Please provide a single OpenRC file as argument."
    Exit
}

ElseIf (-Not (Test-Path $args[0])) {
    Write-Host "The OpenRC file you specified doesn't exist!"
    Exit
}
Else {
    $openrc = $args[0]
    $rcerror = "The file you specified doesn't seem to be a valid OpenRC file"

    # With the addition of Keystone, to use an openstack cloud you should
    # authenticate against keystone, which returns a **Token** and **Service
    # Catalog**.  The catalog contains the endpoint for all services the
    # user/tenant has access to - including nova, glance, keystone, swift.
    #
    # *NOTE*: Using the 2.0 *auth api* does not mean that compute api is 2.0.  We
    # will use the 1.1 *compute api*
    
    $os_project_name = Select-String -Path $openrc -Pattern 'export OS_PROJECT_NAME'
    If ($os_project_name) {
        $OS_PROJECT_NAME = ([string]($os_project_name)).Split("=")[1].Replace("`"","")
        Write-Host "project-name:" -ForegroundColor Yellow $OS_PROJECT_NAME
    }
    Else {
        Write-Host $rcerror
        Exit
    }

    $os_auth_url = Select-String -Path $openrc -Pattern 'export OS_AUTH_URL'
    If ($os_auth_url) {
        $OS_AUTH_URL = ([string]($os_auth_url)).Split("=")[1].Replace("`"","")
        Write-Host "Openstack API URL:" $OS_AUTH_URL -ForegroundColor Yellow
    }
    Else {
        Write-Host $rcerror
        Exit
    }

    # In addition to the owning entity (tenant), openstack stores the entity
    # performing the action as the **user**.

    $os_username = Select-String -Path $openrc -Pattern 'export OS_USERNAME'
    If ($os_username) {
        $OS_USERNAME = ([string]($os_username)).Split("=")[1].Replace("`"","")
        Write-Host "Openstack Username:"$OS_USERNAME -ForegroundColor Yellow
    }
    Else {
        Write-Host $rcerror
        Exit
    }

    # With Keystone you pass the keystone password.
    $temp_password = Select-String -Path $openrc -Pattern 'export OS_PASSWORD'
if ($temp_password -match 'OS_PASSWORD\s*=\s*["''](.+?)["'']') {
    $OS_PASSWORD = $matches[1]
    Write-Host "OpenStack Password: $OS_PASSWORD" -ForegroundColor Yellow
} else {
    Write-Host 'No Password found.' -ForegroundColor Red
    $OS_PASSWORD = Read-Host "Please enter your password" -MaskInput
}
	###Adding variable OS_REGION_NAME and OS_IDENTITY_API_VERSION
	
    $os_region_name = Select-String -Path $openrc -Pattern 'export OS_REGION_NAME'
    If ($os_region_name) {
        $OS_REGION_NAME = ([string]($os_region_name)).Split("=")[1].Replace("`"","")
    }
    Else {
        Write-Host $rcerror
        Exit
    }
	
	    $os_identity_api_version = Select-String -Path $openrc -Pattern 'OS_IDENTITY_API_VERSION'
    If ($os_identity_api_version) {
        $OS_IDENTITY_API_VERSION = ([string]($os_identity_api_version)).Split("=")[1].Replace("`"","")
        Write-Host "Openstack API version:"$OS_IDENTITY_API_VERSION -ForegroundColor Yellow
    }
    Else {
        Write-Host $rcerror
        Exit
    }
$OS_PROJECT_ID = Select-String -Path $openrc -Pattern 'oS_PROJECT_ID'
If ($OS_PROJECT_ID) {
    $OS_PROJECT_ID = ([string]($OS_PROJECT_ID)).Split("=")[1].Replace("`"","")
    Write-Host "Project ID:"$OS_PROJECT_ID -ForegroundColor Yellow
}
Else {
    Write-Host $rcerror
    Exit
}

$OS_USER_DOMAIN_NAME = Select-String -Path $openrc -Pattern 'export OS_USER_DOMAIN_NAME'
    If ($OS_USER_DOMAIN_NAME) {
        $OS_USER_DOMAIN_NAME = ([string]($OS_USER_DOMAIN_NAME)).Split("=")[1].Replace("`"","")
        Write-Host "Openstack Domain Name:"$OS_USER_DOMAIN_NAME -ForegroundColor Yellow
    }
    Else {
        Write-Host $rcerror
        Exit
    }


}
Write-Host "Applying Enviromental variable..." -ForegroundColor White
$env:OS_USERNAME="$OS_USERNAME"
$env:OS_PASSWORD = "$OS_PASSWORD"
$env:OS_IDENTITY_API_VERSION="$OS_IDENTITY_API_VERSION"
$env:OS_AUTH_URL="$OS_AUTH_URL"
$env:OS_PROJECT_ID="$OS_PROJECT_ID"
$env:OS_USER_DOMAIN_NAME = "$OS_USER_DOMAIN_NAME"
Write-Host "Done." -ForegroundColor Green
