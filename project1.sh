#!/bin/bash

# Function to calculate the median length of sequences
calculate_optimal_length() {
    awk '!/^>/ { print length($0) }' "$1" | sort -n | awk ' { a[i++]=$1; } END { x=int((i-1)/2); if (i % 2 == 0) print (a[x] + a[x+1])/2; else print a[x]; }'
}

# Function to crop sequences to the optimal length
crop_sequences() {
    input_file="$1"
    output_file="$2"
    optimal_length=$(calculate_optimal_length "$input_file")
    awk '!/^>/ { seq=$0; len=length(seq); if (len >= '$optimal_length') { start=(len - '$optimal_length') / 2 + 1; print substr(seq, start, '$optimal_length'); } }' "$input_file" > "$output_file"
}

# Function to generate inaccessible regions
generate_inaccessible_regions() {
    awk 'NR==1 {start=$3+1} NR>1 && (end != $2 || (end - 1) < $2) {if(start<=$2){print $1 "\t" start "\t" $2-1; start=$3+1}} {end=$3} NR > 1 && NR < FNR {print} END {if(start<end) {print $1 "\t" start "\t" end}}' "$1" > "$2"
}


# Function to run bedtools getfasta command
run_bedtools_getfasta() {
    local fasta_file="$1"
    local bed_file="$2"
    local output_file="$3"
    bedtools getfasta -fi "$fasta_file" -bed "$bed_file" -fo "$output_file"
}

# Function to get the length of the first sequence in the accessible text file
get_first_sequence_length() {
    local input_file="$1"
    local first_sequence=$(head -n 2 "$input_file" | tail -n 1)
    local sequence_length=${#first_sequence}
    echo "$sequence_length"
}

# Function to trim the inaccessible text file to have sequences with the same length as the first sequence in the accessible text file
trim_inaccessible_file() {
    local accessible_file="$1"
    local inaccessible_file="$2"
    local output_file="$3"
    
    # Get the length of the first sequence in the accessible file
    local sequence_length=$(get_first_sequence_length "$accessible_file")
    
    # Trim the inaccessible file to have sequences with the same length as the first sequence in the accessible file
    awk -v len="$sequence_length" '{ sequence = substr($0, 1, len); print sequence }' "$inaccessible_file" > "$output_file"
}

# Prompt the user for input and output filenames
read -p "Enter access input filename: " input_filename
read -p "Enter access output filename: " output_filename

# Crop sequences and display the optimal length
crop_sequences "$input_filename" "$output_filename"
echo "Optimal length: $(calculate_optimal_length "$input_filename")"

# Prompt the user for input and output file names
read -p "Enter the path to the accessible bed file: " accessible_bed_file
read -p "Enter the path to the output unaccess bed file: " output_bed_file

# Generate inaccessible regions and store in output file
generate_inaccessible_regions "$accessible_bed_file" "$output_bed_file"

echo "Inaccessible bed file generated at: $output_bed_file"


fasta_file="/users/shanmuk/reference/hg38.fa"
bed_file="/users/shanmuk/unacc_file.bed"
output_file="/users/shanmuk/unacc_file.txt"

run_bedtools_getfasta "$fasta_file" "$bed_file" "$output_file"


# Prompt the user for input and output file names
read -p "Enter the path to the accessible text file: " accessible_file
read -p "Enter the path to the inaccessible text file: " inaccessible_file
read -p "Enter the path to the output trimmed inaccessible text file: " output_file

# Trim the inaccessible file to have sequences with the same length as the first sequence in the accessible file
trim_inaccessible_file "$accessible_file" "$inaccessible_file" "$output_file"

echo "Trimmed inaccessible text file generated at: $output_file"





