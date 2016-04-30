# A simple test for modelgen... This is nowhere near a unit test, but it gives me a baseline

from modelgen import *


# load model parameters into modelparams
ModelParams.init_settings(Engine.model_name)
print "Running Modelgen tests"
# this script implements a test of the modelgen module.
automated = False
authoritative = False  # if True, the output from this script will be sent to the reference file.

if automated:
    fout = open("temp.txt", "w")
    # sys.stdout = fout
elif authoritative:
    print "Authoritative test. Recording to file."
    fout = open("modelgen.test", "w")
    # sys.systdout = fout
else:
    fout = sys.stdout

mymodel1 = ModelParams()
mymodel1.params[ModelParams.LAYER_HEIGHT_VAR] = 0.2
mymodel2 = ModelParams()
mymodel2.params[ModelParams.LAYER_HEIGHT_VAR] = 0.3

print >> fout, "Deleting cached models..."
if os.path.exists(Job.cache_path(mymodel1)):
    os.remove(Job.cache_path(mymodel1))
if os.path.exists(Job.cache_path(mymodel2)):
    os.remove(Job.cache_path(mymodel2))

start = time.time()
eng = Engine()
print >> sys.stderr, "Startup: %is" % (time.time() - start)
start = time.time()
print >> fout, "Model 1 exists? " + str(eng.check_exists(mymodel1)[0]) + " Model 2 exists? " + str(
    eng.check_exists(mymodel2)[0])
eng.start_job(mymodel1)
print >> fout, "Started"
print >> sys.stderr, "Start_job: %is" % (time.time() - start)
start = time.time()


def checkdone():
    (done, pth, suc, errtxt) = eng.check_job(mymodel1)
    print >> fout, "Model 1 done=%i fname=%s, success=%i, err='%s'" % (done, pth, suc, errtxt),
    (done, pth, suc, errtxt) = eng.check_job(mymodel2)
    print >> fout, "Model 2 done=%i fname=%s, success=%i, err='%s'" % (done, pth, suc, errtxt)


print >> fout, "Immediately after start: "
checkdone()
print >> sys.stderr, "Check done: %is" % (time.time() - start)
time.sleep(1)

print >> fout, "1s after start: "
start = time.time()
checkdone()
print >> sys.stderr, "Check done: %is" % (time.time() - start)
time.sleep(90)  # time enough for the process to finish

print >> fout, "91s after start:"
start = time.time()
checkdone()
print >> sys.stderr, "Check done: %is" % (time.time() - start)
start = time.time()
checkdone()
print >> sys.stderr, "Check done: %is" % (time.time() - start)

print >> fout, "Model 1 exists? " + str(eng.check_exists(mymodel1)[0]) + " Model 2 exists? " + str(
    eng.check_exists(mymodel2)[0])

if authoritative:
    fout.close()
if automated:
    fout.close()

    # compare with autoritative output
    with open("modelgen.test") as fauth:
        with open("temp.txt") as fthis:
            auth = []
            for line in fauth:
                auth.append(line)
            this = []
            for line in fthis:
                this.append(line)
            diff = difflib.context_diff(auth, this, 'Reference', 'This run')
            sdiff = ''.join(diff)
            if sdiff == '':
                print "Tests passed!"
            print sdiff
            fthis.close()
