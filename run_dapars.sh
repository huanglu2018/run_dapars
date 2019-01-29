## [DaPars](http://lilab.research.bcm.edu/dldcc-web/lilab/zheng/DaPars_Documentation/html/DaPars.html)


source activate dapars
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


bedgraphdir=$output_dir/bedgraph_file
mkdir -p $bedgraphdir

extract_3UTR(){
bedfile=$1
symbol_map=$output_dir/$(basename $bedfile).symbol_map.txt
extracted_3UTR=$output_dir/$(basename $bedfile).extracted_3UTR.txt

less -S $bedfile|awk '{print $4"\t"$4}'|less -S > $symbol_map

python2 $DaPars_Extract_Anno_ex \
    -b $bedfile \
    -s $symbol_map \
    -o $extracted_3UTR
}

get_coverage_bedgraph(){
sort_bam_file=$1
chrominfo_file=$2
bedgraphfile=$bedgraphdir/`basename $sort_bam_file | awk -F '.sort.bam' '{print$1}'`

genomeCoverageBed \
  -bg \
  -ibam $sort_bam_file \
  -g $chrominfo_file \
  -split \
  > $bedgraphfile
}

extract_3UTR $bedfile
caselist_string=`less $case_bam_list_file` ; caselist=(${caselist_string// / })
ctrllist_string=`less $ctrl_bam_list_file` ; ctrllist=(${ctrllist_string// / })
total_bam_list= (${caselist[@]} ${ctrllist[@]})
if [ ${#total_bam_list[@]} -lt 10 ]; then para_num=`${#total_bam_list[@]}`;else para_num=10 ; fi
echo ${total_bam_list[@]} | xargs -L 1 -P $para_num -I {} get_coverage_bedgraph {} $chrominfo_file
Group1=`echo $caselist_string |sed -e 's/ /,/g' `;Group2=`echo $ctrllist_string |sed -e 's/ /,/g' `

echo \
"""
Annotated_3UTR=$extracted_3UTR
Group1_Tophat_aligned_Wig=$Group1
Group2_Tophat_aligned_Wig=$Group2
Output_directory=$output_dir/
Output_result_file=dapars_result
#APA_limit_file=hsTissue_anno_res_none_removed.txt

#Parameters
Num_least_in_group1=1
Num_least_in_group2=1
Coverage_cutoff=30
FDR_cutoff=0.05
PDUI_cutoff=0.5
Fold_change_cutoff=0.59
""" \
  > $output_dir/configure.txt

python2 $DaPars_ex $output_dir/configure.txt |& tee $output_dir"/"`date "+%Y_%m_%d_%H_%M_%S"`"_log.txt"
