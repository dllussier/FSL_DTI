#!/bin/bash

#use this when running on local workstation
#for scripts to run raw DTI dicoms must be placed in subject folder under DTI directory

for i in [subjects separated by one space]
do

#creates additional directories needed for DTI preprocessing scripts
 mkdir $i/DTI/raw/
 mkdir $i/DTI/nifti/
 mkdir $i/DTI/FSL/
 mv $i/DTI/DTI_dicoms/ $i/DTI/raw/DTI_dicoms/

#converts dti dicoms to niftis
 dcm2nii $i/DTI/raw/DTI_dicoms/

#moves and renames files to set up folder to run DTI preporcessing scripts
	mv $i/DTI/raw/DTI_dicoms/x*WIP6dir*.nii.gz $i/DTI/nifti/x6dir.nii.gz
	mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.nii.gz $i/DTI/nifti/6dir.nii.gz
	mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.nii.gz $i/DTI/nifti/64dir.nii.gz
	mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.bval $i/DTI/nifti/6dir.bval
	mv $i/DTI/raw/DTI_dicoms/*WIP6dir*.bvec $i/DTI/nifti/6dir.bvec
	mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.bval $i/DTI/nifti/64dir.bval
	mv $i/DTI/raw/DTI_dicoms/*WIP64dir*.bvec $i/DTI/nifti/64dir.bvec

#runs eddy current correction on dti image
 fsl5.0-eddy_correct $i/DTI/nifti/64dir.nii.gz $i/DTI/FSL/64dir_ecc.nii.gz 0
   
#runs brain extraction tool to create binary mask and then renames mask appropriately
 fsl5.0-bet2 $i/DTI/FSL/64dir_ecc.nii.gz $i/DTI/FSL/64dir_ecc_brain.nii.gz -f .3 -m
 mv $i/DTI/FSL/64dir_ecc_brain.nii.gz_mask.nii.gz $i/DTI/FSL/64dir_ecc_brain_mask.nii.gz

#fits tensors to the preprocessed diffusion weighted images
 fsl5.0-dtifit -k $i/DTI/FSL/64dir_ecc.nii.gz -o $i/DTI/FSL/dti -m $i/DTI/FSL/64dir_ecc_brain_mask.nii.gz -r $i/DTI/nifti/64dir.bvec -b $i/DTI/nifti/64dir.bval

#runs bedpostx to build sampling distributions at each voxelto be used later for tractography
 fsl5.0-bedpostx $i/DTI/FSL/

#registers DTI to the T1 MPRAGE
 mkdir $i/DTI/FSL/DTI.bedpost/xfms 
 fsl5.0-flirt -in $i/DTI/FSL/DTI.bedpost/nodif_brain -ref $i/T1/T1_brain.nii -omat $i/DTI/FSL/DTI.bedpost/xfms/diff2str.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost mutualinfo
 fsl5.0-convert_xfm -omat $i/DTI/FSL/DTI.bedpost/xfms/str2diff.mat -inverse $i/DTI/FSL/DTI.bedpost/xfms/diff2str.mat
 fsl5.0-flirt -in $i/T1/T1_brain.nii -ref $FSLDIR/etc/standard/avg152T1_brain -omat $i/DTI/FSL/DTI.bedpost/xfms/str2standard.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost corratio
 fsl5.0-convert_xfm -omat $i/DTI/FSL/DTI.bedpost/xfms/standard2str.mat -inverse $i/DTI/FSL/DTI.bedpost/xfms/str2standard.mat
 fsl5.0-convert_xfm -omat $i/DTI/FSL/DTI.bedpost/xfms/diff2standard.mat -concat $i/DTI/FSL/DTI.bedpost/xfms/str2standard.mat $i/DTI/FSL/DTI.bedpost/xfms/diff2str.mat
 fsl5.0-convert_xfm -omat $i/DTI/FSL/DTI.bedpost/xfms/standard2diff.mat -inverse $i/DTI/FSL/DTI.bedpost/xfms/diff2standard.mat

done
