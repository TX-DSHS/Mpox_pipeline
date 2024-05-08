#!/usr/bin/env python3
# parse results from nextclade json file generated from mpox pipeline
# Usage: python3 
# Author: Jie.Lu@dshs.texas.gov
version = "1.0-5/8/2024"
import json
import argparse
import logging
import pandas as pd
from datetime import date

my_parser = argparse.ArgumentParser()
my_parser.add_argument("-i", help = 'Installation path', default = "/bioinformatics/Mpox_pipeline")
my_parser.add_argument("-r", help = 'Run name')

args = my_parser.parse_args()
install_dir = args.i
run_name = args.r

logging.basicConfig(filename = 'parseFromNextclade.log', filemode = 'a', level = logging.DEBUG)
logging.info('Parsing from Nextclade results {} starting on run {}'.format(version, run_name))
logging.info(str(date.today()))

result_dir = install_dir + "/results/" + run_name 
json_path = result_dir + "/nextclade/nextclade.json"
tsv_file_path = result_dir + "/OPG057_substitutions.txt"

class nextclade(object):
    def __init__(self, json_path):
        with open(json_path, 'r') as file:
            json_data = json.load(file)
            self.results = json_data["results"]      

    def get_gene(self, tsv_file_path, gene = "OPG057"):
        df = pd.DataFrame()
        sampleName = []
        aaSub = []
        aaDel = []
        aaIns = []
        for result in self.results:
            sampleName.append(result['seqName'])
            if result["aaSubstitutions"]:
                for s in result["aaSubstitutions"]:
                    #print(s["cdsName"])
                    if s["cdsName"] == gene:
                        #print(s["refAa"] + str(s["pos"]) + s["qryAa"])
                        aaSub.append(s["refAa"] + str(s["pos"]) + s["qryAa"])
            else:
                aaSub.append("Not_Detected")

            if result["aaDeletions"]:
                for s in result["aaDeletions"]:
                    if s["cdsName"] == gene:
                        aaDel.append(s["refAa"] + str(s["pos"]) + s["qryAa"])
            else:
                aaDel.append("Not_Detected")
           
            if result["aaInsertions"]:
                for s in result["aaInsertions"]:
                    if s["cdsName"] == gene:
                        aaIns.append(s["refAa"] + str(s["pos"]) + s["qryAa"])
            else:
                aaIns.append("Not_Detected")
        df["sample"] = sampleName
        df["aaSubstitutions"] = aaSub
        df["aaDeletions"] = aaDel
        df["aaInsertions"] = aaIns              
        df.to_csv(tsv_file_path, sep='\t', index = False)    
         

if __name__ == "__main__":
    results = nextclade(json_path)
    results.get_gene(tsv_file_path)
