<#
    .SYNOPSIS
        Invoke a SQL Server database copy.

    .DESCRIPTION
        This command will resolve the common use case of a database copy
        required to copy a production system database back to a test or
        development system.
#>
function Invoke-SqlDbCopy
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        # Source SQL Server to copy the database from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceSqlInstance,

        # SQL credential to the source SQL Server. If not specified, use the
        # integrated Windows authentication.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $SourceSqlCredential,

        # Name of the database to copy.
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceDatabaseName,

        # Destination SQL Server to copy the database too.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationSqlInstance,

        # SQL credential to the destination SQL Server. If not specified, use the
        # integrated Windows authentication.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DestinationSqlCredential,

        # Name of the restored database. If not specified, the name is equals to
        # the source database.
        [Parameter(Mandatory = $false)]
        [System.String]
        $DestinationDatabaseName
    )

    $ErrorActionPreference = 'Stop'

    # Define and verify the connection splat to the source SQL Server.
    $sqlSource = @{
        SqlInstance = $SourceSqlInstance
    }
    if ($PSBoundParameters.ContainsKey('SourceSqlCredential'))
    {
        $sqlSource['SqlCredential'] = $SourceSqlCredential
    }
    $sqlSourceData = Test-SqlConnection @sqlSource -Verbose:$false

    # Define and verify the connection splat to the destination SQL Server.
    $sqlDestination = @{
        SqlInstance = $DestinationSqlInstance
    }
    if ($PSBoundParameters.ContainsKey('DestinationSqlCredential'))
    {
        $sqlDestination['SqlCredential'] = $DestinationSqlCredential
    }
    $sqlDestinationData = Test-SqlConnection @sqlDestination -Verbose:$false

    # Check if the destination database name was specified. If not, use the
    # source database name.
    if (-not $PSBoundParameters.ContainsKey('DestinationDatabaseName'))
    {
        if ($sqlSourceData.Server -eq $sqlDestinationData.Server)
        {
            throw 'Please specify the destination database name if the source and destination SQL Server is the same.'
        }

        $DestinationDatabaseName = $SourceDatabaseName
    }

    Write-Verbose "SQL DB COPY: Query last full disk backup from database '$SourceDatabaseName' on SQL Server '$SourceSqlInstance'."

    # Get and check the last full backup from the source SQL Server.
    $backup = Get-DbaDbBackupHistory @sqlSource -Database $SourceDatabaseName -DeviceType 'Disk' -LastFull
    if ($null -eq $backup)
    {
        throw "Last full backup to disk not found for database '$SourceDatabaseName' on SQL Server '$SourceSqlInstance'."
    }

    if ($PSCmdlet.ShouldProcess("SQL Se1rver $DestinationSqlInstance", "Restore Database $DestinationDatabaseName"))
    {
        Write-Verbose "SQL DB COPY: Restore database '$DestinationDatabaseName' to SQL Server '$DestinationSqlInstance' from path '$($backup.Path)'."

        # Performe the database restore on the destination SQL Server.
        Restore-DbaDatabase @sqlDestination -Path $backup.Path -DatabaseName $DestinationDatabaseName -ReplaceDbNameInFile -WithReplace

        Write-Verbose "SQL DB COPY: Update database '$DestinationDatabaseName' owner to 'sa'."

        # Restore the owner to sa.
        Invoke-DbaQuery @sqlDestination -Database $DestinationDatabaseName -Query "ALTER AUTHORIZATION ON DATABASE::[$DestinationDatabaseName] TO [sa]"

        # Get all files and rename their logical file names, if they do not match
        # the physical file name.
        $files = Get-DbaDbFile @sqlDestination -Database $DestinationDatabaseName
        foreach ($file in $files)
        {
            $actualLogicalName   = $file.LogicalName
            $expectedLogicalName = [System.IO.Path]::GetFileNameWithoutExtension($file.PhysicalName)
            if ($actualLogicalName -ne $expectedLogicalName)
            {
                Write-Verbose "SQL DB COPY: Rename database '$DestinationDatabaseName' logical file '$actualLogicalName' to '$expectedLogicalName'."

                Invoke-DbaQuery @sqlDestination -Database $DestinationDatabaseName -Query "ALTER DATABASE [$DestinationDatabaseName] MODIFY FILE (NAME=N'$actualLogicalName', NEWNAME=N'$expectedLogicalName')"
            }
        }
    }
}
