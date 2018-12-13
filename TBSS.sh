#!/bin/bash

module load fsl/5.0.10

#copy dti_FA to current folder from subject folder and rename 
cp ${subjid}/dti_FA.nii.gz ${subjid}_bv_dti_FA.nii.gz

#creates datastructure
tbss_1_preproc *.nii.gz
	
#registration of FA maps to standard space
#output in ./FA/
tbss_2_reg -T
	
#for study specific skeleton template based on average of all FA volumes
tbss_3_postreg -S
	
# for standard skeleton template
# output: in ./stats/
tbss_3_postreg -T
	
# thresholds mean_skeleton and creates individual skeletons
# output: all_FA_skeletonised.nii.gz
tbss_4_prestats 0.2
	
# extract mean FA and mimimum and maximum:
fslstats -t stats/all_FA_skeletonised.nii.gz -k . stats/mean_FA_skeleton_mask -M > ./mean_FA.txt
fslstats -t stats/all_FA_skeletonised.nii.gz -k . stats/mean_FA_skeleton_mask -l 0.0001 -R > ./min_max.txt
