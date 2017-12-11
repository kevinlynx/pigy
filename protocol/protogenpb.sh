#!/bin/bash
protofiles=`ls | grep .proto`
rm -rf *.pb
for f in ${protofiles[*]} 
do
	./protoc $f -o ${f/".proto"/".pb"} 2>&1
done
