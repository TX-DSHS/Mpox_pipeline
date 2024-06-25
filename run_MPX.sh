# Run Monkey Pox pipeline
# Author: Jie.Lu@dshs.texas.gov
version="1.0-11/14/2022"

basedir="/home/dnalab"
mkdir -p $basedir/results/$1
echo "Running Monkey Pox version %s" $version > $basedir/results/$1/run_mpx.log

# Copy and unzip the fastq files from s3
#aws s3 cp --recursive s3://804609861260-bioinformatics-infectious-disease/MPX/RAW_RUNS/$1 $basedir/reads/$1 --region us-gov-west-1
aws s3 cp s3://804609861260-bioinformatics-infectious-disease/MPX/RAW_RUNS/$1.zip $basedir/reads/zip --region us-gov-west-1
mkdir $basedir/reads/$1
unzip -j $basedir/reads/zip/$1.zip -d $basedir/reads/$1

# # Check if the file size is < 1Mb, if yes then move to a folder
# mkdir $basedir/reads/$1/small_size_fastq
# echo "Checking the size of the file..." >> $basedir/results/$1/run_mpx.log
# touch $basedir/results/$1/$1_failed_file_size.log
# for fastq in $basedir/reads/$1/*.gz; do
#   myfilesize=$(stat --format=%s $fastq)
#   if [ $myfilesize -lt 1000000 ]; then
#     mv $fastq $basedir/reads/$1/small_size_fastq
#     echo $fastq  >> $basedir/results/$1/failed_file_size.log
#   fi
# done

# Run Cecret pipeline
cd $basedir/results/$1
nextflow run UPHL-BioNGS/Cecret -r 3.4.20221121 -c /home/dnalab/monkeypox/config/mpx.config --reads $basedir/reads/$1 --outdir $basedir/results/$1 #\
#--ivar_variants_options '-q 20 -t 0.15' --ivar_consensus_options '-q 20 -t 0.15 -n N'

rm -r $basedir/results/$1/work
rm -r $basedir/results/$1/shuffled
rm -r $basedir/results/$1/seqyclean
rm -r $basedir/results/$1/ivar_trim
rm -r $basedir/results/$1/filter
rm -r $basedir/results/$1/aligned
rm $basedir/results/zip/$1.zip

# # Zip and copy the results to s3
rm -f $basedir/results/zip/$1_result.zip
rm -f $basedir/results/zip/$1_report.zip
zip -rj $basedir/results/zip/$1_report $basedir/results/$1/*.csv $basedir/results/$1/*.txt $basedir/results/$1/*.log
aws s3 cp $basedir/results/zip/$1_report.zip s3://804609861260-bioinformatics-infectious-disease/MPX/REPORT/$1_report.zip --region us-gov-west-1
zip -r $basedir/results/zip/$1_result $basedir/results/$1
aws s3 cp $basedir/results/zip/$1_result.zip s3://804609861260-bioinformatics-infectious-disease/MPX/ANALYSIS_RESULTS/$1_result.zip --region us-gov-west-1

rm $basedir/results/zip/$1_result.zip 
rm $basedir/reads/zip/$1_result.zip 
rm -r $basedir/reads/$1
