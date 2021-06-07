suppressMessages(library(seqinr, quietly = T, warn.conflicts = FALSE))

inFile=commandArgs()[6]
outFile=commandArgs()[7]
readLength=as.numeric(commandArgs()[8])

#print(readLength)



fna=read.fasta(inFile)


j=1
for(j in 1:length(fna)) { 
  oldSeq=fna[[j]]
 # print(oldSeq)
  fna[[j]]=oldSeq[c(1:readLength,(length(oldSeq)-readLength):length(oldSeq)) ]
  attributes(fna[[j]]) = attributes(oldSeq)
}

write.fasta(fna,names = names(fna),  file.out = outFile)


