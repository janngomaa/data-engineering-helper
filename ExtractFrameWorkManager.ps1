function Main(){
    # Get Files"
    $ModelsPath = "T:\Temp\models\"
    $Ids = Get-ChildItem -Path $ModelsPath |Select Name
	$NbFiles = $Ids.Count
	
	Write-Output "Extraction started. $NbFiles model files to process."
    ForEach ($Id in $Ids){
        
        $FileId = $Id.Name
        $Path = $ModelsPath + $FileId
		
		Write-Output "Processing File $FileId"
		
        [xml]$xmlElm = Get-Content -Path $Path
        # Get Project Name
        $ProjectName = $xmlElm.project.name
        $Packages = $xmlElm.project.packages.package
        $Namespaces = $xmlElm.project.namespace
        $DataSources = $xmlElm.project.dataSources.dataSource
       
        if($DataSources){
            ExtractDataSourcessData -ds $DataSources
        }

        if($DataSources -eq $null){
            Write-Output "*** DataSources is null for the file $FileId"
        }

        if($Packages){
            ExtractPacksData -Packs $Packages
        }

        if($Packages -eq $null){
            Write-Output "*** Packages is null for the file $FileId"
        }

        if($Namespaces){
            ExtractQSData -RootNamespace $Namespaces
        }

        if($Namespaces -eq $null){
            Write-Output "*** Namespaces is null for the file $FileId"
        }
    }
}

function ExtractDataSourcessData($ds) {
    $DsDest = "data-sources/" + $FileId + ".csv"
    $ds | Export-Csv -Delimiter "|" -NoTypeInformation -Path $DsDest
}

# Extract Packages
function ExtractPacksData($Packs) {
    $PacksData = @()
    ForEach($pack in $Packs) {
        $PackData = (New-Object PSObject | Add-Member -PassThru NoteProperty "PackageName" $pack.name."#text" `
            | Add-Member -PassThru NoteProperty "PackageDescription" $pack.description."#text" `
            | Add-Member -PassThru NoteProperty "LastChanged" $pack.lastChanged `
            | Add-Member -PassThru NoteProperty "LastChangedBy" $pack.lastChangedBy `
            | Add-Member -PassThru NoteProperty "LastPublished" $pack.lastPublished `
            | Add-Member -PassThru NoteProperty "LastPublishedCMPath" $pack.lastPublishedCMPath  `
            | Add-Member -PassThru NoteProperty "ProjectName" $pack.ProjectName  `
            | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
        )
        $PacksData = $PackData
    }

    $PackDest = "packages/" + $FileId + ".csv"
    $PacksData | Export-Csv -Delimiter "|" -NoTypeInformation -Path $PackDest
}

# Extract Single QuerySubject Info
# $node: parent namespace
# $QSNode: the querySubject to extract
function Process-QSNode($node, $QSNode) {
    $sep = "|@"
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
        | Add-Member -PassThru NoteProperty "QSTableType" $QSNode.definition.dbQuery.tableType `
        | Add-Member -PassThru NoteProperty "QSLastChanged" $QSNode.lastChanged `
        | Add-Member -PassThru NoteProperty "QSLastChangedBy" $QSNode.lastChangedBy `
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
    $DestFileName = "query-subjects/" + $FileId + ".csv"

    $QSData | Select NamespaceName, NamespaceDescription, NamespaceLastChanged, NamespaceLastChangedBy, QSName, QSLastChanged, QSLastChangedBy, QSSQL, QSModelQuery, QSSourceTable, QSTableType, QSDataSource, SourceFileId `
    | Export-Csv -Path $DestFileName -NoTypeInformation
}
