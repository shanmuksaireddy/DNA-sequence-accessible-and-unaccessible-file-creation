#!/bin/bash

# Function to calculate average length of sequences
calculate_average_length() {
    local input_file="$1"
    local total_length=$(awk '{ total += length($0) } END { print total }' "$input_file")
    local total_sequences=$(wc -l < "$input_file")
    echo $((total_length / total_sequences))
}

# Function to extract nucleotide sequences and store them in a new file
extract_nucleotide_sequences() {
    local input_file="$1"
    local output_file="$2"
    grep -o '[ATGC]*' "$input_file" > "$output_file"
}

# Function to discard sequences shorter than the average length and trim sequences longer than the average length
discard_and_trim_sequences() {
    local input_file="$1"
    local output_file="$2"
    local average_length="$3"
    awk -v average_length="$average_length" '{ if (length($0) >= average_length) print substr($0, 1, average_length) }' "$input_file" > "$output_file"
}

# Step 1: Extract nucleotide sequences and store them in a new file
extract_nucleotide_sequences "A1.txt" "exp1_nucleotide_sequences.txt"

# Calculate the average length of sequences
average_length=$(calculate_average_length "exp1_nucleotide_sequences.txt")

# Discard sequences shorter than the average length and trim sequences longer than the average length
discard_and_trim_sequences "exp1_nucleotide_sequences.txt" "exp1_accessible_sequences.txt" "$average_length"

# Define input and output files
narrowpeak_file="ENCFF226WSC.bed"
negative_regions_file="exp1_negative_regions.bed"

# Sort the narrowpeak file
sort -k1,1 -k2,2n "$narrowpeak_file" > sorted.bed

# Iterate through the sorted narrowpeak file
prev_end=0
while read -r chrom start end rest; do
    # Calculate middle region between consecutive accessible regions
    if [ "$prev_end" -ne 0 ]; then
        middle_start=$((prev_end + 1))
        middle_end=$((start - 1))
        # Output middle region if it exists
        if [ "$middle_end" -gt "$middle_start" ]; then
            echo "$chrom $middle_start $middle_end" >> "$negative_regions_file"
        fi
    fi
    prev_end="$end"
done < sorted.bed

# Remove temporary sorted file
rm sorted.bed

# Convert spaces to tabs in negative regions file
awk '{$1=$1}1' OFS="\t" "$negative_regions_file" > exp1_negative_regions_tab.bed

# Use bedtools to get fasta sequences
bedtools getfasta -fi /users/Shanmuk/reference/hg38.fa -bed /users/Shanmuk/exp1_negative_regions_tab.bed -fo /users/Shanmuk/exp1_negative_regions.txt

# Step 1: Extract nucleotide sequences and store them in a new file
extract_nucleotide_sequences "exp1_negative_regions.txt" "exp1_Neg_nucleotide_sequences.txt"

# Calculate the average length of sequences
average_length=$(calculate_average_length "exp1_Neg_nucleotide_sequences.txt")

# Discard sequences shorter than the average length and trim sequences longer than the average length
discard_and_trim_sequences "exp1_Neg_nucleotide_sequences.txt" "exp1_inaccessible_sequences.txt" "$average_length"
