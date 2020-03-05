<#
    .SYNOPSIS
        Test the SQL connection to a target SQL Server.

    .DESCRIPTION
        Test the connection to a SQL Server. Currently only the .NET SqlClient
        provider is supported.

    .INPUTS
        None.

    .OUTPUTS
        SqlServerFever.TestConnectionResult. Result of the test connection.

    .EXAMPLE
        PS C:\> Test-SqlConnection -ComputerName 'SQL01'
        Test the SQL connection to SQL01 with Windows authentication.

    .EXAMPLE
        PS C:\> Test-SqlConnection -ComputerName 'SQL01' -Credential 'sa'
        Test the SQL connection to SQL01 with SQL authentication.

    .EXAMPLE
        PS C:\> Test-SqlConnection -ComputerName 'SQL01' -Database 'Demo0'
        Test the SQL connection to SQL01 to the database Demo0.

    .EXAMPLE
        PS C:\> Test-SqlConnection -ComputerName 'SQL01' -Encrypt
        Test the SQL connection to SQL01 with encryption.

    .LINK
        https://github.com/claudiospizzi/SqlServerFever
#>
function Test-SqlConnection
{
    [CmdletBinding()]
    param
    (
        # SQL instance name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlInstance,

        # SQL Login. If not specified, use integrated security.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $SqlCredential,

        # Database to connect, be default master.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Database = 'master',

        # The SQL client provider to use for the test.
        [Parameter(Mandatory = $false)]
        [ValidateSet('SqlClient')]
        [System.String]
        $Provider,

        # Option to enable encryption for the SQL Server connection.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Encrypt,

        # Option to specify a test query on the selected database.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Query
    )

    # Default connection string with target server and database
    $connectionString = 'Data Source={0}; Initial Catalog={1}' -f $SqlInstance, $Database

    # Depending on the credential parameter, append the user id and password or
    # the integrated security note.
    if ($PSBoundParameters.ContainsKey('SqlCredential'))
    {
        $connectionString += '; User ID={0}; Password={1}' -f $SqlCredential.UserName, $SqlCredential.GetNetworkCredential().Password
    }
    else
    {
        $connectionString += '; Integrated Security=true'
    }

    # Finally, force an encrypted connection.
    if ($Encrypt.IsPresent)
    {
        $connectionString += '; Encrypt=true'
    }

    # Remove the passwort on the verbose output
    $connectionStringDisplay = $connectionString
    if ($PSBoundParameters.ContainsKey('SqlCredential'))
    {
        $connectionStringDisplay = $connectionString -replace ($SqlCredential.GetNetworkCredential().Password -as [System.String]), '***'
    }

    Write-Verbose "SQL Connection String: $connectionStringDisplay"

    try
    {
        $sqlConnection = New-Object -TypeName 'System.Data.SqlClient.SqlConnection' -ArgumentList $connectionString
        $sqlConnection.Open()

        try
        {
            $sqlCommand = New-Object -TypeName 'System.Data.SqlClient.SqlCommand' -ArgumentList "SELECT @@SPID, SYSTEM_USER, USER, (SELECT auth_scheme FROM sys.dm_exec_connections WHERE session_id = @@SPID), (SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID), @@SERVERNAME, @@SERVICENAME, @@VERSION, (SELECT create_date FROM sys.databases WHERE name = 'tempdb')", $sqlConnection
            $sqlReader = $sqlCommand.ExecuteReader()

            while ($sqlReader.Read())
            {
                [PSCustomObject] @{
                    PSTypeName       = 'SqlServerFever.TestConnectionResult'
                    ConnectionString = $connectionStringProtected
                    Id               = $sqlReader[0]
                    Login            = $sqlReader[1]
                    User             = $sqlReader[2]
                    Protocol         = $sqlReader[3]
                    Encryption       = $sqlReader[4]
                    Server           = $sqlReader[5]
                    Instance         = $sqlReader[6]
                    Version          = ($sqlReader[7] -as [System.String]).Split("`n")[0]
                    StartDate        = $sqlReader[8]
                    Uptime           = [System.DateTime]::Now - $sqlReader[8]
                }
            }
        }
        finally
        {
            if ($null -ne $sqlReader)
            {
                $sqlReader.Close()
                $sqlReader.Dispose()
            }
        }

        if ($PSBoundParameters.ContainsKey('Query'))
        {
            try
            {
                $sqlCommand = New-Object -TypeName 'System.Data.SqlClient.SqlCommand' -ArgumentList $Query, $sqlConnection
                $sqlReader = $sqlCommand.ExecuteReader()

                while ($sqlReader.Read())
                {
                    $objectHashtable = [Ordered] @{}
                    for ($i = 0; $i -lt $sqlReader.FieldCount; $i++)
                    {
                        $objectHashtable["Field$i"] = $sqlReader[$i]
                    }
                    [PSCustomObject] $objectHashtable
                }
            }
            finally
            {
                if ($null -ne $sqlReader)
                {
                    $sqlReader.Close()
                    $sqlReader.Dispose()
                }
            }
        }
    }
    finally
    {
        if ($null -ne $sqlConnection)
        {
            $sqlConnection.Close()
            $sqlConnection.Dispose()
        }
    }
}