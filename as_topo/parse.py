
with open('cycles_6272.txt','r') as fp:
    for l in fp:
        l = l.strip()
        if l.startswith('D'):
            l_arr = l.split('\t')
            print(l_arr[1] + ' ' + l_arr[2])
