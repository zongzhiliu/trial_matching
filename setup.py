from setuptools import setup, find_packages
with open('README.md') as f:
    readme = f.read()

setup(
    name='s4_trial_matching', version='0.1.0',
    description='Match the trial criteria to the patients',
    long_description=readme, long_description_content_type='text/markdown',
    author='Zongzhi Zachary Liu, Yun Mai',
    author_email='zongzhi.liu@sema4.com, yun.mai@sema4.com',
    url='https://github.com/sema4genomics/s4-trial-matching',
    #license=license,
    packages=find_packages(exclude=('tests', 'docs')),
    scripts=[]
)
