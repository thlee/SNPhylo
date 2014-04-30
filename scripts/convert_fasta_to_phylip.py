import sys

fasta_file = sys.argv[1]

seq_ids = []
seq_data = {}
seq_id, seq_buffer = None, []
for line in open(fasta_file, "r"):
    line = line.strip()
    if line.startswith(">"):
        if seq_buffer:
            seq_data[seq_id] = ''.join(seq_buffer)
            seq_ids.append(seq_id)
        seq_id, seq_buffer = line[1:], []
    else:
        seq_buffer.append(line)

seq_data[seq_id] = ''.join(seq_buffer)
seq_ids.append(seq_id)
seq_len = len(seq_data[seq_id])

print len(seq_data), len(seq_data[seq_id])
for seq_id in seq_ids:
    seq = seq_data[seq_id]
    sys.stdout.write(seq_id[:10] + (" " * (10 - len(seq_id))))
    for i in range(0, 50 if seq_len >= 50 else seq_len, 10):
        sys.stdout.write(" " + seq[i:i+10])
    print

if seq_len > 50:
    for j in range(50, seq_len, 60):
        print
        for seq_id in seq_ids:
            seq = seq_data[seq_id]
            for i in range(j, (j + 60) if seq_len >= (j + 60) else seq_len, 10):
                sys.stdout.write((" " if i > j else "") + seq[i:i+10])
            print
