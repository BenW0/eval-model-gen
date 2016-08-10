
import qrcode
k = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_H)
k.add_data("TESTING 12")
k.make(fit=True)
len(k.get_matrix())
data = k.get_matrix()
size = len(data)
print(size)
newdata = []
for i in range(size):
    newline = []
    for j in range(size):
        newline.append(data[i][j])
    newdata.append(newline)

newdata = [item for sublist in newdata for item in sublist]
newdata = [1 if item else 0 for item in newdata]
print(newdata)