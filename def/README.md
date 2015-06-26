## PHR - Personal Health Record

### Purpose 
The NLM Personal Health Record (PHR) is a web-based tool that allows consumers to keep track of their own health information as well as that of their children and elderly or other dependents. It takes advantage of national coding and terminology standards and can be used to serve as a bridge for meaningful data exchange between electronic health record systems.

### Context 
This application was developed by staff in the Computer Science Branch at the U.S. National Library of Medicine under the direction of Clement J. McDonald, MD, Director, Lister Hill National Center for Biomedical Communications. Federal research staff includes Paul Lynch, Project Manager, and Ye Wang, Senior Systems Developer at the National Library of Medicine. 

The PHR is a web-based system.  The server code is written primarily in Ruby on Rails, and the client side code is written in Javascript.  A MySQL database contains both user and program data.

### Key Features

####	Single Account for All Family Members 
The entire family's health information is managed within one account by creating individual health records for each family member. 

####	Customized Health Reminders 
The PHR creates customized health reminders for each user based on national health guidelines by analyzing all of the demographic and clinical data entered for each individual. Reminders are based on U.S. Preventive Services Task Force (USPSTF) and Centers for Disease Control (CDC) guidelines but can be customized to use any sources. The reminders include brief informative text as well as links to the appropriate USPSTF or CDC recommendation.

####	Date Reminders 
The PHR creates date-based reminders for each user based information entered for things like medication refill due dates, next appointment dates, next vaccination dates, etc. 

####	Links to Trusted Health Information 
The PHR provides one-click access to trusted consumer health oriented resources both inside and outside the US National Library of Medicine through the use of information buttons that are created at the time of data entry.

####	Comprehensive Test Panel and Health Tracker Entry 
The PHR includes an "Add Tests & Measures" section where individuals can enter laboratory, radiology, and diagnostic test results. They can also keep track of disease and symptoms such as diabetes and wheezing associated with asthma, as well as lifestyle measures such as sleep, mood, nutrition, and exercise. These panels are easy to customize for a particular group or institution's needs.

####	Test Panel Flowsheet
The PHR results timeline flowsheet allows the user to see test results and health trackers over time. The graphing feature makes it easy to view test results and health trends as well as get detailed information about specific data points.

####	Data Sharing 
The data for an individual may be shared with others.  This feature is enabled only on the request of the person who created the health record, by explicitly granting read-only access to someone they specify.

####	A Basic HTML Mode
The standard mode for the PHR uses Javascript extensively.  For users who need a more accessible version, a “Basic” mode is provided which requires no javascript.

------------------------------------------------------
Please see the project wiki for installation details, technical documentation, and general notes.

-----------------------------------------------------
This software, PHR, was developed by the National Library of Medicine (NLM) Lister Hill National Center for Biomedical Communications (LHNCBC), part of the National Institutes of Health (NIH).

Please cite as: [http://lhncbc.nlm.nih.gov/project/nlm-personal-health-record-phr](http://lhncbc.nlm.nih.gov/project/nlm-personal-health-record-phr)

This software is distributed under a BSD-style open-source license. See [LICENSE.md](https://github.com/lhncbc/PHR/blob/master/LICENSE.md).

No warranty or indemnification for damages resulting from claims brought by third parties whose proprietary rights may be infringed by your usage of this software are provided by any of the owners.