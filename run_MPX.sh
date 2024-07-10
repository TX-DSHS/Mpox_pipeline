# Run Monkey Pox pipeline
# Author: Jie.Lu@dshs.texas.gov
version="v1.1-05/08/2024"
# set the base directory
aws_bucket="s3://804609861260-bioinformatics-infectious-disease"

# Read the aws bucket name from file aws_bucket.txt
#aws_bucket=$(cat aws_bucket.txt)
install_dir=$PWD

#set the base directory
basedir=$install_dir/results/$1
rm -rf $basedir
mkdir -p $basedir

mkdir -p $basedir
echo "Running Mpox pipeline version" $version > $basedir/run_mpx.log

# Copy and unzip the fastq files from s3
mkdir -p $install_dir/reads/zip
aws s3 cp $aws_bucket/MPX/RAW_RUNS/$1.zip $install_dir/reads/zip --region us-gov-west-1
mkdir -p $install_dir/reads/$1
unzip -j $install_dir/reads/zip/$1.zip -d $install_dir/reads/$1

# Check if the file size is < 1Mb, if yes then move to a folder
mkdir $basedir/reads/$1/small_size_fastq
echo "Checking the size of the file..." >> $basedir/results/$1/run_mpx.log
touch $basedir/results/$1/$1_failed_file_size.log
for fastq in $basedir/reads/$1/*.gz; do
  myfilesize=$(stat --format=%s $fastq)
  if [ $myfilesize -lt 1000000 ]; then
    mv $fastq $basedir/reads/$1/small_size_fastq
    echo $fastq  >> $basedir/results/$1/failed_file_size.log
  fi
done

# Run Cecret pipeline
cd $basedir
conda activate mpx
export NXF_SINGULARITY_CACHEDIR=$install_dir/singularity_cache
nextflow pull UPHL-BioNGS/Cecret
#nextflow run UPHL-BioNGS/Cecret -c $install_dir/config/mpx.config --reads $install_dir/reads/$1 --outdir $basedir

nextflow run UPHL-BioNGS/Cecret --reads $install_dir/reads/$1 --outdir $basedir \
         -profile singularity,mpx_yale \
         -r 3.15.24191 \
         --minimum_depth 30
#--ivar_variants_options '-q 20 -t 0.03' --ivar_consensus_options '-q 20 -t 0.03 -n N'

# if the run is not successful, exit the script
if [ $? -ne 0 ]; then
    echo "The Mpox Cecret pipeline failed" 1>>$basedir/run_mpx.log
fi

rm -r $basedir/work
rm -r $basedir/shuffled
rm -r $basedir/seqyclean
#rm -r $basedir/ivar_trim
rm -r $basedir/filter
#rm -r $basedir/aligned

mkdir -p $install_dir/results/zip/
rm $install_dir/results/zip/$1.zip

# Parse OPG057 gene aaSubstitution from Nextclade json
python3 $install_dir/parseFromNextclade.py -r $1
conda deactivate
if [ $? -ne 0 ]; then
    echo "Parsing from nextclade json failed" 1>>$basedir/run_mpx.log
fi

# # Zip and copy the results to s3
rm -f $install_dir/results/zip/$1_result.zip
rm -f $install_dir/results/zip/$1_report.zip
zip -rj $install_dir/results/zip/$1_report $basedir/*.csv $basedir/*.txt $basedir/*.log
aws s3 cp $install_dir/results/zip/$1_report.zip $aws_bucket/MPX/REPORT/$1_report.zip --region us-gov-west-1
# if the transfer is not successful, exit the script
if [ $? -ne 0 ]; then
    echo "The report zip file $1.zip failed to transfer to the S3 bucket" 1>>$basedir/run_mpx.log
    exit 1
fi

zip -r $install_dir/results/zip/$1_result $basedir
aws s3 cp $install_dir/results/zip/$1_result.zip $aws_bucket/MPX/ANALYSIS_RESULTS/$1_result.zip --region us-gov-west-1
if [ $? -ne 0 ]; then
    echo "The result zip file $1.zip failed to transfer to the S3 bucket" 1>>$basedir/run_mpx.log
    exit 1
fi

rm $install_dir/results/zip/$1_result.zip 
rm $install_dir/reads/zip/$1.zip 
rm -r $install_dir/reads/$1
