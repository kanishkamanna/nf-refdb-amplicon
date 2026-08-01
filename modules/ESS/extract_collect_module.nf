/*
----------------------------------------------------------------------------------------
    ESS_EXTRACT_FROM_COLLECTION

    Extracts artifacts from a QIIME 2 collection
 ----------------------------------------------------------------------------------------
 */

process ESS_EXTRACT_FROM_COLLECTION {
    label 'process_low'
    tag "Extracting artifacts from collection"
    conda params.qiime_conda_env

    input:
    path sequences_collection
    path taxonomy_collection
    val target_gene

    output:
    path "sequences.qza", emit: sequences
    path "taxonomy.qza",  emit: taxonomy
    path "versions.yml",  emit: versions

    script:
    """
    #!/usr/bin/env python3
    import os
    import shutil

    def find_qza_in_collection(collection_dir, target_gene):
        \"\"\"
        QIIME 2 collection output directories contain .qza files
        keyed by the collection member name. Find the appropriate one.
        \"\"\"
        collection_path = collection_dir
        
        # Look for .qza files in the collection directory
        qza_files = []
        for f in os.listdir(collection_path):
            if f.endswith('.qza'):
                qza_files.append(f)
        
        if len(qza_files) == 0:
            raise FileNotFoundError(
                f"No .qza files found in collection directory: {collection_path}"
            )
        
        # If there's only one file, use it
        if len(qza_files) == 1:
            return os.path.join(collection_path, qza_files[0])
        
        # If multiple, try to match by target gene name
        for f in qza_files:
            if target_gene.lower() in f.lower():
                return os.path.join(collection_path, f)
        
        # Fallback: return the first one
        print(f"WARNING: Multiple .qza files found, using first: {qza_files[0]}")
        return os.path.join(collection_path, qza_files[0])

    target = "${target_gene}"

    seq_qza = find_qza_in_collection("${sequences_collection}", target)
    tax_qza = find_qza_in_collection("${taxonomy_collection}", target)

    shutil.copy2(seq_qza, "sequences.qza")
    shutil.copy2(tax_qza, "taxonomy.qza")

    # Write versions
    with open("versions.yml", "w") as f:
        f.write('"ESS_EXTRACT_FROM_COLLECTION":\\n')
        f.write("    python: 3.12\\n")
    """
}