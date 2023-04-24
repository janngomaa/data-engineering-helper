function Main(){

	$sw = [Diagnostics.Stopwatch]::StartNew()
	
	$date = Get-Date -Format "yyyy-MM-dd"
	$csvDelimiter = "|"
	
	$ModelsPath = "T:\Temp\models_all\"
	$HomeDir = "T:\Temp\model_data_$date\"
	$ResultDir = $HomeDir + "results\"
	$PackDir = $HomeDir + "packages\"
	$DataSourceDir = $HomeDir + "data-sources\"
	$QuerySubjectDir = $HomeDir + "query-subjects\"
	
	$LogFile = $HomeDir + "log_$date.log"
	
	$dirs = $HomeDir, $PackDir, $DataSourceDir, $QuerySubjectDir, $ResultDir
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
    }
	
	$finaleModelsFile = $ResultDir + "models.csv"
	$finalDataSourceFile = $ResultDir + "data-sources.csv"
	$finalPackagesFile = $ResultDir + "packages.csv"
	$finalQSFile = $ResultDir + "query-subjects.csv"
	
	$Models | Export-Csv -Delimiter $csvDelimiter -NoTypeInformation -Path $finaleModelsFile
	
	MergeFiles -inputPath $DataSourceDir -outputFile $finalDataSourceFile
	MergeFiles -inputPath $PackDir -outputFile $finalPackagesFile
	MergeFiles -inputPath $QuerySubjectDir -outputFile $finalQSFile
	
	Write-Output "Done. See consolidated data at $ResultDir" >> $LogFile
	Write-Output "For more details see data at $HomeDir" >> $LogFile
	Write-Output "Done. See consolidated data at $ResultDir"
	Write-Output "Done. See data at $HomeDir"
	
	$sw.Stop()
    $elapsedTime = $sw.Elapsed.ToString()

    Write-Output "Elapsed time: $elapsedTime" >> $LogFile
}

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

# Extract Single QuerySubject Info
# $node: parent namespace
# $QSNode: the querySubject to extract
function Process-QSNode($node, $QSNode) {
    $sql = $QSNode.definition.dbQuery.sql
    $rawSql = $null
    $sourceTable = $sql.table -replace '[\r\n\s]+', ' '

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
    $rawSql = $rawSql -replace '[\r\n\s]+', ' '
	
	if ($rawSql -match "(?i)FROM\s+((?:\w+)(?:\s*(?:,|JOIN)\s*\w+)*)") {
		$calculatedSrcTable = $matches[1] -split '\s*(?:,|JOIN)\s*'
	}
    $modelQuery = $QSNode.definition.modelQuery.sql."#text"  -replace '[\r\n\s]+', ' '

    $result = (New-Object PSObject | Add-Member -PassThru NoteProperty "NamespaceName" $node.name."#text" `
        | Add-Member -PassThru NoteProperty "NamespaceDescription" $node.description."#text" `
        | Add-Member -PassThru NoteProperty "NamespaceLastChanged" $node.lastChanged `
        | Add-Member -PassThru NoteProperty "NamespaceLastChangedBy" $node.lastChangedBy `
        | Add-Member -PassThru NoteProperty "QSName" $QSNode.name."#text" `
        | Add-Member -PassThru NoteProperty "QSDataSource" $QSNode.definition.dbQuery.sources.dataSourceRef `
        | Add-Member -PassThru NoteProperty "QSSQL" $rawSql `
        | Add-Member -PassThru NoteProperty "QSModelQuery" $modelQuery `
        | Add-Member -PassThru NoteProperty "QSSourceTable" $sourceTable `
		| Add-Member -PassThru NoteProperty "QSCalculatedSrcTable" $calculatedSrcTable `
        | Add-Member -PassThru NoteProperty "QSTableType" $QSNode.definition.dbQuery.tableType `
        | Add-Member -PassThru NoteProperty "QSLastChanged" $QSNode.lastChanged `
        | Add-Member -PassThru NoteProperty "QSLastChangedBy" $QSNode.lastChangedBy `
		| Add-Member -PassThru NoteProperty "ProjectName" $ProjectName `
        | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
    )
    return $result
}

# Process Namespaces
# $node: root namespace / folder
function Process-NamespaceNode($node) {
    $results = @()
    if ($node) {
        #Process QuerySubjects
        $querySubjects = $node.querySubject
        if($querySubjects){
            ForEach ($qs in $querySubjects){
                $results += Process-QSNode -node $node -QSNode $qs
            }
        }
        #Process SubNamespaces
        $childNamespaces = $node.namespace
        if( $childNamespaces){
            ForEach ($cNamespace in $childNamespaces){
                $childResults = Process-NamespaceNode -node $cNamespace
                $results += $childResults
            }
        }
        #Process SubFolders
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

# Process the Root Namespace and Save Data
# $node: root namespace / folder
function ExtractQSData($RootNamespace) {
    $QSData = Process-NamespaceNode -node $RootNamespace
    $DestFileName = $QuerySubjectDir + $FileId + ".csv"

    $QSData | Select NamespaceName, NamespaceDescription, NamespaceLastChanged, NamespaceLastChangedBy, QSName, QSLastChanged, QSLastChangedBy, QSSQL, QSModelQuery, QSSourceTable, QSCalculatedSrcTable, QSTableType, QSDataSource, ProjectName, SourceFileId `
    | Export-Csv -Path $DestFileName -Delimiter $csvDelimiter -NoTypeInformation
}


function MergeFiles( $inputPath, $outputFile){
	Write-Output "Merging CSV files under $inputPath to $outputFile." >> $LogFile
	# Get a list of all CSV files in the input path
	$csvFiles = Get-ChildItem -Path $inputPath

	# Check if there are any files to process
	if ($csvFiles) {
		# Process the first file and include headers
		$csvFiles[0].FullName | Import-Csv -Delimiter $csvDelimiter| Export-Csv -Path $outputFile -Delimiter $csvDelimiter -NoTypeInformation
		
		# Process the remaining files and exclude the first line (header)
		for ($i = 1; $i -lt $csvFiles.Count; $i++) {
			$content = Get-Content $csvFiles[$i].FullName | Select-Object -Skip 1
			Add-Content $outputFile $content
		}
	} else {
		Write-Host "No CSV files found in $inputPath."
	}
}
