import sys
import math

def getShufflePartitionSize(s:int, c:int, p:int):
    totalSparkPartitions = (s*1024)/p
    coreCycles = totalSparkPartitions/c
    suggestedShufflePartitions = math.floor(coreCycles)*c

    maxPartitionBytesString = 'spark.conf.set("spark.sql.files.maxPartitionBytes", ' + str(p * 1024 * 1024) + ')'
    suggestedShufflePartitionsString = 'spark.conf.set("spark.sql.shuffle.partitions", ' + str(suggestedShufflePartitions) + ')'

    # print out the numbers
    print("Total Spark partitions: " + str(totalSparkPartitions))
    print("Cluster core cycles: " + str(coreCycles))
    print("Suggested shuffle partitions: " + str(suggestedShufflePartitions))

    # print the settings to use
    print("")
    print("--Settings to use--")
    print(maxPartitionBytesString)
    print(suggestedShufflePartitionsString)


if __name__ == '__main__':
    shuffleSize = int(sys.argv[1])
    cores = int(sys.argv[2])
    partitionSize = int(sys.argv[3])

    getShufflePartitionSize(shuffleSize, cores, partitionSize)