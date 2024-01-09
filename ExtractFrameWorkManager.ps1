##*****************************************************************************************##
##***	This script extracts Cognos Framework Manager Models information to CSV files.	***##
##***	The script look at an given folder ($ModelsPath), process all model.xml         ***##
##***	files located in that folder. The extracted data are available under            ***##
##***	the folder named result.							***##
##***	Please contact @janngomaa if you need help.					***##
##*****************************************************************************************##


# Main Function
function Main($debug=$false){

	$sw = [Diagnostics.Stopwatch]::StartNew()
	
	$date = Get-Date -Format "yyyy-MM-dd"
	$csvDelimiter = "|"
	
	$ModelsPath = "T:\Temp\models_all\"
	$HomeDir = "T:\Temp\model_data_$date\"
	$ResultDir = $HomeDir + "results\"
	$PackDir = $HomeDir + "packages\"
	$DataSourceDir = $HomeDir + "data-sources\"
	$QuerySubjectDir = $HomeDir + "query-subjects\"
	$SrcTablesDir = $HomeDir + "src-tables\"
	$SrcTablesTmpDir = $HomeDir + "src-tables-tmp\"
	
	$LogFile = $HomeDir + "log_$date.log"
	
	$dirs = $HomeDir, $PackDir, $DataSourceDir, $QuerySubjectDir, $SrcTablesDir, $SrcTablesTmpDir, $ResultDir
	ForEach($d in $dirs){
		if (Test-Path $d) {
			Remove-Item $d -Recurse -Force
		}
		New-Item -ItemType Directory -Path $d
	}

    $Ids = Get-ChildItem -Path $ModelsPath |Select Name
	$NbFiles = $Ids.Count
	
	Write-Output "Extraction started. For more information see log file: $LogFile."
	
	Write-Output "Extraction started with the following params:" >> $LogFile
	Write-Output "Models Location = $ModelsPath." >> $LogFile
	Write-Output "HomeDir = $HomeDir.`nNumber of Files (model.xml) to Process = $NbFiles." >> $LogFile
	
	$Models = @()
	$counter = 0
    ForEach ($Id in $Ids){
        
        $FileId = $Id.Name
        $Path = $ModelsPath + $FileId
		
		Write-Output "Processing File $FileId." >> $LogFile
		
        [xml]$xmlElm = Get-Content -Path $Path
        # Get Project Name
        $ProjectName = $xmlElm.project.name
        $Packages = $xmlElm.project.packages.package
        $Namespaces = $xmlElm.project.namespace
        $DataSources = $xmlElm.project.dataSources.dataSource
       
        if($DataSources){
            ExtractDataSourcessData -DataSources $DataSources
        } else {
            Write-Output "*** DataSources is null for the file $FileId." >> $LogFile
        }

        if($Packages){
            ExtractPacksData -Packs $Packages
        } else {
            Write-Output "*** Packages is null for the file $FileId." >> $LogFile
        }

        if($Namespaces){
            ExtractQSData -RootNamespace $Namespaces
        }

        if($Namespaces -eq $null){
            Write-Output "*** Namespaces is null for the file $FileId." >> $LogFile
        }
		
		$cModel = (New-Object PSObject | Add-Member -PassThru NoteProperty "ModelName" $ProjectName `
            | Add-Member -PassThru NoteProperty "SourceFileId" $FileId )
		$Models += $cModel
		
		$TablesDestFileName = $SrcTablesDir + "Tables_" + $FileId + ".csv"
		#$filesMask = ($FileId -replace '\s', '') + "*"
		MergeFiles -inputPath $SrcTablesTmpDir -outputFile $TablesDestFileName -removeTmpFiles $true
		
		if ($debug -and $counter -eq 3) {
			break
		}
		$counter++
    }
	
	$finaleModelsFile = $ResultDir + "models.csv"
	$finalDataSourceFile = $ResultDir + "data-sources.csv"
	$finalPackagesFile = $ResultDir + "packages.csv"
	$finalQSFile = $ResultDir + "query-subjects.csv"
	$finalTablesFile = $ResultDir + "src-tables.csv"
	
	$Models | Export-Csv -Delimiter $csvDelimiter -NoTypeInformation -Path $finaleModelsFile
	
	MergeFiles -inputPath $DataSourceDir -outputFile $finalDataSourceFile
	MergeFiles -inputPath $PackDir -outputFile $finalPackagesFile
	MergeFiles -inputPath $QuerySubjectDir -outputFile $finalQSFile
	MergeFiles -inputPath $SrcTablesDir -outputFile $finalTablesFile
	
	Write-Output "Done. See consolidated data at $ResultDir" >> $LogFile
	Write-Output "For more details see data at $HomeDir" >> $LogFile
	Write-Output "Done. See consolidated data at $ResultDir"
	Write-Output "Done. See data at $HomeDir"
	
	$sw.Stop()
    $elapsedTime = $sw.Elapsed.ToString()

    Write-Output "Elapsed time: $elapsedTime" >> $LogFile
}

# Extract DataSources
function ExtractDataSourcessData($DataSources) {
	$dsData = @()
    $DsDest = $DataSourceDir + $FileId + ".csv"
	
	ForEach($curDs in $DataSources) {
        $cdsData = (New-Object PSObject | Add-Member -PassThru NoteProperty "DataSourceName" $curDs.name `
            | Add-Member -PassThru NoteProperty "queryProcessing" $curDs.queryProcessing `
            | Add-Member -PassThru NoteProperty "cmDataSource" $curDs.cmDataSource `
            | Add-Member -PassThru NoteProperty "Catalog" $curDs.catalog `
            | Add-Member -PassThru NoteProperty "Schema" $curDs.schema `
            | Add-Member -PassThru NoteProperty "QueryType" $curDs.type.queryType `
			| Add-Member -PassThru NoteProperty "QueryInterface" $curDs.type.interface  `
            | Add-Member -PassThru NoteProperty "ProjectName" $ProjectName  `
            | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
        )
        $dsData += $cdsData
    }

    $dsData | Export-Csv -Delimiter $csvDelimiter -NoTypeInformation -Path $DsDest
}

# Extract Packages
function ExtractPacksData($Packs) {
    $PacksData = @()
    ForEach($pack in $Packs) {
	
		$PackName = $pack.name."#text" -replace '[\r\n\s]+', ' '
		if($pack.name.GetType().BaseType.Name -eq "Array"){
			$PackName = $pack.name[0]."#text" -replace '[\r\n\s]+', ' '
		}
		
		$packDesc = $pack.description."#text" -replace '[\r\n\s]+', ' '
		
        $PackData = (New-Object PSObject | Add-Member -PassThru NoteProperty "PackageName" $PackName `
            | Add-Member -PassThru NoteProperty "PackageDescription" $packDesc `
            | Add-Member -PassThru NoteProperty "LastChanged" $pack.lastChanged `
            | Add-Member -PassThru NoteProperty "LastChangedBy" $pack.lastChangedBy `
            | Add-Member -PassThru NoteProperty "LastPublished" $pack.lastPublished `
            | Add-Member -PassThru NoteProperty "LastPublishedCMPath" $pack.lastPublishedCMPath  `
            | Add-Member -PassThru NoteProperty "ProjectName" $ProjectName  `
            | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
        )
        $PacksData += $PackData
    }

    $PackDest = $PackDir + $FileId + ".csv"
    $PacksData | Export-Csv -Delimiter $csvDelimiter -NoTypeInformation -Path $PackDest
}

# Process the Root Namespace and Save Data
# $node: root namespace / folder
function ExtractQSData($RootNamespace) {
    $QSData = Process-NamespaceNode -node $RootNamespace
    $QSDestFileName = $QuerySubjectDir + $FileId + ".csv"

    $QSData | Select NamespaceName, NamespaceDescription, NamespaceLastChanged, NamespaceLastChangedBy, QSName, QSLastChanged, QSLastChangedBy, QSSQL, QSCalculatedSrcTables, QSModelQuery, QSSourceTable, QSTableType, QSDataSource, ProjectName, QSId, SourceFileId `
    | Export-Csv -Path $QSDestFileName -Delimiter $csvDelimiter -NoTypeInformation
}

# Process Namespaces
# $node: root namespace / folder
function Process-NamespaceNode($node) {
    $results = @()
    if ($node) {
        #Process QuerySubjects of the Namespace
        $querySubjects = $node.querySubject
        if($querySubjects){
            ForEach ($qs in $querySubjects){
                $results += Process-QSNode -node $node -QSNode $qs
            }
        }
        #Process SubNamespaces of the Namespace
        $childNamespaces = $node.namespace
        if( $childNamespaces){
            ForEach ($cNamespace in $childNamespaces){
                $childResults = Process-NamespaceNode -node $cNamespace
                $results += $childResults
            }
        }
        #Process SubFolders of the Namespace
        $ChildFolders = $node.folder
        if($ChildFolders){
            ForEach ($sf in $ChildFolders){
                $childFResults = Process-NamespaceNode -node $sf
                $results += $childFResults
            }
        }
    }

    return $results
}

# Extract Single QuerySubject Info
# $node: parent namespace
# $QSNode: the querySubject to extract
function Process-QSNode($node, $QSNode) {
    $sql = $QSNode.definition.dbQuery.sql
    $rawSql = $null
	$calculatedSrcTables = $null
	$srcTables = @()
	#Get the source table if defined in the the Query subject
    $sourceTable = $sql.table -replace '[\r\n\s]+', ' ' -replace '[\[\]\"]+', ''
	$sourceTable = Get-LastPart -inputString $sourceTable + 

	# Get SQL query
    $sql.ChildNodes | ForEach-Object {
        if ($_.NodeType -eq 'Text') {
            $rawSql += $_.Value
        } else {
            $rawSql += $_.InnerText
        }

    }
    if($rawSql -eq $null ){
        $rawSql = $sql."#text"
    }
	# Clean the SQL
    $rawSql = $rawSql -replace '[\r\n\s]+', ' ' -replace '[\[\]\"]+', ''
	$rawSql = $rawSql.ToUpper()
	
	$modelQuery = $QSNode.definition.modelQuery.sql."#text"  -replace '[\r\n\s]+', ' '
	$QSName = $QSNode.name."#text" -replace '[\r\n\s]+', ' '
	$NamespaceName = $node.name."#text"
	$QSId = $FileId + $ProjectName + $NamespaceName + $QSName 
	$QSId  =  Get-TextHash -rawId $QSId
	
	# Extract source tables
	if ($rawSql -match "(?i)FROM\s+((?:\w+(?:\.\w+)*)(?:\s*(?:,|JOIN)\s*\w+(?:\.\w+)*)*)") {
		$calculatedSrcTables = $matches[1] -split '\s*(?:,|JOIN)\s*'
		
		ForEach($t in $calculatedSrcTables){
			$table = Get-LastPart -inputString $t
			$srcTables = $srcTables + (New-Object PSObject | Add-Member -PassThru NoteProperty "TableName" $table `
			| Add-Member -PassThru NoteProperty "TableFullName" $t `
			| Add-Member -PassThru NoteProperty "QuerySubject" $QSName `
			| Add-Member -PassThru NoteProperty "Namespace" $NamespaceName `
			| Add-Member -PassThru NoteProperty "ProjectName" $ProjectName `
			| Add-Member -PassThru NoteProperty "QSId" $QSId `
			| Add-Member -PassThru NoteProperty "SourceFileId" $FileId )
		}
		
		

		$calculatedSrcTables = $($calculatedSrcTables -join ', ') -replace "`t", " " -replace "`r`n|`n", " "
	}
	if( $sourceTable ){
		$srcTables = $srcTables + (New-Object PSObject | Add-Member -PassThru NoteProperty "TableName" $sourceTable `
			| Add-Member -PassThru NoteProperty "TableFullName" $sourceTable `
			| Add-Member -PassThru NoteProperty "QuerySubject" $QSName `
			| Add-Member -PassThru NoteProperty "Namespace" $NamespaceName `
			| Add-Member -PassThru NoteProperty "ProjectName" $ProjectName `
			| Add-Member -PassThru NoteProperty "QSId" $QSId `
			| Add-Member -PassThru NoteProperty "SourceFileId" $FileId )
	}
	# Create the file name
	$tablesFileName = $FileId + $NamespaceName + $QSName
	$sanitizedFilename = Sanitize-FilePath $tablesFileName
	$sanitizedFilename = $sanitizedFilename.Substring(0, [Math]::Min(220, $sanitizedFilename.Length))
	$sanitizedFilename = "$sanitizedFilename.csv"
	$SrcTablesDestFileName = Join-Path -Path $SrcTablesTmpDir -ChildPath $sanitizedFilename
	# Export the Source Tables Data
	$srcTables | Export-Csv -Path $SrcTablesDestFileName -Delimiter $csvDelimiter -NoTypeInformation
	
    

    $QSResult = (New-Object PSObject | Add-Member -PassThru NoteProperty "NamespaceName" $NamespaceName `
        | Add-Member -PassThru NoteProperty "NamespaceDescription" $node.description."#text" `
        | Add-Member -PassThru NoteProperty "NamespaceLastChanged" $node.lastChanged `
        | Add-Member -PassThru NoteProperty "NamespaceLastChangedBy" $node.lastChangedBy `
        | Add-Member -PassThru NoteProperty "QSName" $QSName `
        | Add-Member -PassThru NoteProperty "QSDataSource" $QSNode.definition.dbQuery.sources.dataSourceRef `
        | Add-Member -PassThru NoteProperty "QSSQL" $rawSql `
		| Add-Member -PassThru NoteProperty "QSCalculatedSrcTables" $calculatedSrcTables `
        | Add-Member -PassThru NoteProperty "QSModelQuery" $modelQuery `
        | Add-Member -PassThru NoteProperty "QSSourceTable" $sourceTable `
        | Add-Member -PassThru NoteProperty "QSTableType" $QSNode.definition.dbQuery.tableType `
        | Add-Member -PassThru NoteProperty "QSLastChanged" $QSNode.lastChanged `
        | Add-Member -PassThru NoteProperty "QSLastChangedBy" $QSNode.lastChangedBy `
		| Add-Member -PassThru NoteProperty "ProjectName" $ProjectName `
		| Add-Member -PassThru NoteProperty "QSId" $QSId `
        | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
    )
    return $QSResult
}

function MergeFiles( $inputPath, $outputFile, $mask="*", $removeTmpFiles=$false ){
	Write-Output "Merging CSV files under $inputPath to $outputFile." >> $LogFile
	# Get a list of all CSV files in the input path
	$csvFiles = Get-ChildItem -Path $inputPath -Filter $mask

	# Check if there are any files to process
	if ($csvFiles -and $csvFiles.Count) {
		# Process the first file and include headers
		$cFile = $csvFiles[0].FullName
		if (Test-Path $cFile) {
			$csvFiles[0].FullName | Import-Csv -Delimiter $csvDelimiter| Export-Csv -Path $outputFile -Delimiter $csvDelimiter -NoTypeInformation
			<#
			if ($removeTmpFiles) {
					Remove-Item -Path $csvFiles[0].FullName -Force
				}
			#>
		}else{
				Write-Output "File $cFile doesn't exists." >> $LogFile
		}
		
		# Process the remaining files and exclude the first line (header)
		for ($i = 1; $i -lt $csvFiles.Count; $i++) {
			$cFile = $csvFiles[$i].FullName
			if (Test-Path $cFile) {
				$content = Get-Content $csvFiles[$i].FullName | Select-Object -Skip 1
				Add-Content $outputFile $content
				<#
				if ($removeTmpFiles) {
					Remove-Item -Path $csvFiles[$i].FullName -Force
				}
				#>
			} else{
				Write-Output "File $cFile doesn't exists." >> $LogFile
			}
			
		}
	} else {
		Write-Output "No CSV files found in $inputPath with mask = $mask." >> $LogFile
	}
	
	
	if ($removeTmpFiles) {
		Get-ChildItem -Path $inputPath -Filter $mask | ForEach-Object {
			Remove-Item -Path $_.FullName -Force
		}
    }
}

# Helper Functions

function Get-LastPart {
    param($inputString)
    if ($inputString -match "(?i)(?:.*\.)?(\w+)$") {
        return $matches[1]
    } else {
        return $inputString
    }
}

function Sanitize-FilePath {
    param (
        [string]$Path
    )
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $regex = "[{0}]" -f [RegEx]::Escape($invalidChars)
    $sanitizedPath = [RegEx]::Replace($Path, $regex, '-')
    return $sanitizedPath
}

function Get-TextHash {
    param (
        [Parameter(Mandatory=$true)]
        [string]$rawId
    )

    $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create('SHA256')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawId)
    $hashBytes = $hashAlgorithm.ComputeHash($bytes)
    $hash = [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()

    return $hash
}
