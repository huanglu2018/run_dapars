## [DaPars](http://lilab.research.bcm.edu/dldcc-web/lilab/zheng/DaPars_Documentation/html/DaPars.html)

### Generate UTR region annotation

* gene.bed: download from [ncbi](http://genome.ucsc.edu/cgi-bin/hgTables?hgsid=706106087_t39m9ht7VsmfxSGcM0RXClJTi7Rb&clade=mammal&org=Mouse&db=mm10&hgta_group=genes&hgta_track=refSeqComposite&hgta_table=0&hgta_regionType=genome&position=chr12%3A56694976-56714605&hgta_outputType=bed&hgta_outFileName=ucsc.gencode19.basic.bed)


input_dir=
output_dir=/public/home/huanglu/mouse_APA_AS/APA/dapars/output  
DaPars_Extract_Anno_ex=/public/home/huanglu/APA/src/dapars/DaPars_Extract_Anno.py
DaPars_ex=/public/home/huanglu/APA/src/dapars/DaPars_main.py
bedfile=/public/home/huanglu/APA/ncbi.mouse.gencode19.basic.bed
# extracted_3UTR=/public/home/huanglu/APA/extracted_3UTR.bed
ref_genome=/public/home/huanglu/resource/genome/mm10.fa
bwa_threads=10
case_bam_list_file=
ctrl_bam_list_file=

out_prefix=(young_vs_old young_vs_KO)

logdir=$output_dir/log
mkdir -p $logdir

bedgraphdir=$output_dir/bedgraph_file
mkdir -p $bedgraphdir

symbol_map=$output_dir/$(basename $bedfile).symbol_map.txt
extracted_3UTR=$output_dir/$(basename $bedfile).extracted_3UTR.txt

less -S $bedfile|awk '{print $4"\t"$4}'|less -S > $symbol_map

python2 $DaPars_Extract_Anno_ex \
    -b $bedfile \
    -s $symbol_map \
    -o $extracted_3UTR

caselist_string=`less $case_bam_list_file` ; caselist=(${caselist_string// / })
ctrllist_string=`less $ctrl_bam_list_file` ; ctrllist=(${ctrllist_string// / })
total_bam_list= (${caselist[@]} ${caselist[@]})

get_coverage_bedgraph(){

chrominfo_file=$output_dir/chromInfo.txt
ref_version=`basename $ref_genome | awk -F'.fa' '{print$1}'`
wget http://hgdownload.soe.ucsc.edu/goldenPath/$ref_version/database/chromInfo.txt.gz -O ${chrominfo_file}.gz || \
echo wget chromInfo failed !!! ref_genome should be hg19.fa, hg38.fa, mm9.fa, or mm10.fa !!!
gzip -dc ${chrominfo_file}.gz > ${chrominfo_file}.gz

sort_bam_file=$1
bedgraphfile=$bedgraphdir/`basename $sort_bam_file | awk -F '.sort.bam' '{print$1}'`

echo "genomeCoverageBed -bg -ibam $sort_bam_file -g $chrominfo_file -split > $bedgraphfile"
genomeCoverageBed \
  -bg \
  -ibam $sort_bam_file \
  -g $chrominfo_file \
  -split \
  > $bedgraphfile

}


if [ ${#total_bam_list[@]} -lt 10 ]  
then
	para_num=`${#total_bam_list[@]}`
else
	para_num=10
fi

echo ${total_bam_list[@]} | xargs -L 1 -P $para_num -I {} get_coverage_bedgraph {}


  configure_file=$configdir/${i}.txt

  if [ $i = young_vs_old ]
  then
  Group1=/public/home/huanglu/mouse_APA_AS/data/young/WT2.bedgraph,/public/home/huanglu/mouse_APA_AS/data/young/WT5.bedgraph,/public/home/huanglu/mouse_APA_AS/data/young/WT6.bedgraph
  Group2=/public/home/huanglu/mouse_APA_AS/data/old/old1.bedgraph,/public/home/huanglu/mouse_APA_AS/data/old/old2.bedgraph,/public/home/huanglu/mouse_APA_AS/data/old/old3.bedgraph
  fi
  
  if [ $i = young_vs_KO ]
  then
  Group1=/public/home/huanglu/mouse_APA_AS/data/young/WT2.bedgraph,/public/home/huanglu/mouse_APA_AS/data/young/WT5.bedgraph,/public/home/huanglu/mouse_APA_AS/data/young/WT6.bedgraph
  Group2=/public/home/huanglu/mouse_APA_AS/data/KO/KL1.bedgraph,/public/home/huanglu/mouse_APA_AS/data/KO/KL5.bedgraph,/public/home/huanglu/mouse_APA_AS/data/KO/KL6.bedgraph
  fi

  echo \
"""
Annotated_3UTR=$extracted_3UTR
Group1_Tophat_aligned_Wig=$Group1
Group2_Tophat_aligned_Wig=$Group2
Output_directory=$output_dir/
Output_result_file=$i
#APA_limit_file=hsTissue_anno_res_none_removed.txt

#Parameters
Num_least_in_group1=1
Num_least_in_group2=1
Coverage_cutoff=30
FDR_cutoff=0.05
PDUI_cutoff=0.5
Fold_change_cutoff=0.59
""" \
  > $configure_file



for i in `ls $configdir|grep -v "log"`
do
  
done

run_dapars(){
python2 $DaPars_ex $configdir"/"$1 |& tee $logdir"/"$i"_"`date "+%Y_%m_%d_%H_%M_%S"`"_log.txt"
}

ls $configdir|xargs -L 1 -P 2 -I {} run_dapars {}

