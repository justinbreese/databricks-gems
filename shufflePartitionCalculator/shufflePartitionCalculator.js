function buttonPressed()
{
    var shuffleSize = document.getElementById("shuffleSize").value;
    var cores = parseInt(document.getElementById("cores").value);
    var partitionSize = parseInt(document.getElementById("partitionSize").value);

    var totalSparkPartitions = (shuffleSize*1024)/partitionSize
    var coreCycles = totalSparkPartitions/cores
    var suggestedShufflePartitions = Math.floor(coreCycles)*cores

    var maxPartitionBytesString = 'spark.conf.set("spark.sql.files.maxPartitionBytes", ' + partitionSize * 1024 * 1024 + ')'
    var suggestedShufflePartitionsString = 'spark.conf.set("spark.sql.shuffle.partitions", ' + suggestedShufflePartitions + ')'

    // rewrite the HTML elements on the page
    document.getElementById('suggestedShufflePartitions').innerText = suggestedShufflePartitionsString;
    document.getElementById('maxPartitionBytes').innerText = maxPartitionBytesString;
}