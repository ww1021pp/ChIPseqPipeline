#!/usr/bin/bash
## Merge peaks to a file with all peaks in each sample make it comparable
cd /workspace/rsrch2/panpanliu/project/ChIP_seq/45_ChIPseq20250303/YangF_ChIPseq/
mergePeaks mergePeaks 22Rvl-ict-DMSO.peakCalling 22Rvl-ict-GSK126.peakCalling 22Rvl-iMAPK4-DMSO.peakCalling 22Rvl-iMAPK4-GSK126.peakCalling >MergedPeaks_allSamples.peak 

## get the peaks Counts by Homer tagdirectory
annotatePeaks.pl ../MergedPeaks_allSamples.peak mm10 -d /workspace/rsrch2/panpanliu/project/ChIP_seq/45_ChIPseq20250303/04_homer/tagDirectory/23101FL-12-02-17_Uniq/ /workspace/rsrch2/panpanliu/project/ChIP_seq/45_ChIPseq20250303/04_homer/tagDirectory/23101FL-12-02-18_Uniq/ /workspace/rsrch2/panpanliu/project/ChIP_seq/45_ChIPseq20250303/04_homer/tagDirectory/23101FL-12-02-19_Uniq/ /workspace/rsrch2/panpanliu/project/ChIP_seq/45_ChIPseq20250303/04_homer/tagDirectory/23101FL-12-02-20_Uniq/ -raw -size 1000 >MergedPeaks.annotated.raw.txt


