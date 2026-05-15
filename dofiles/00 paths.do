
if "`c(username)'" == "sidhpandit" {
	global nfhs3ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs3ir/IAIR52FL.dta"
	global nfhs4ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs4ir/IAIR74FL.DTA"	
	global nfhs5ir "/Users/sidhpandit/Desktop/data/nfhs/nfhs5ir/IAIR7EFL.DTA"

	global nfhs1br "/Users/sidhpandit/Desktop/data/nfhs/nfhs1br/IABR23FL.DTA"
	global nfhs2br "/Users/sidhpandit/Desktop/data/nfhs/nfhs2br/IABR42FL.dta"
	global nfhs3br "/Users/sidhpandit/Desktop/data/nfhs/nfhs3br/IABR52FL.dta"
	global nfhs4br "/Users/sidhpandit/Desktop/data/nfhs/nfhs4br/IABR74FL.DTA"
	global nfhs5br "/Users/sidhpandit/Desktop/data/nfhs/nfhs5br/IABR7EFL.DTA"
	global dataset "/Users/sidhpandit/Dropbox/maternal nutrition by social group/data/prepared_dataset.dta"

	
	global nfhs1hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs1hr/IAHR23FL.DTA"
	
	cd "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups"
	
	global paths "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/000_paths.do"
	
	global nfhs5mr "/Users/sidhpandit/Desktop/nfhs/nfhs5mr/IAMR7EFL.DTA"
	
	global nfhs5hmr "/Users/sidhpandit/Desktop/data/nfhs/nfhs5hmr/IAPR7EFL.DTA"
	
	global nfhs5hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs5hr/IAHR7EFL.DTA"
	
	global nfhs4hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs4hr/IAHR74FL.DTA"
	
	global nfhs3hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs3hr/IAHR52FL.dta"
	
	global nfhs2hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs2hr/IAHR42FL.DTA"
	
	global nfhs1hr "/Users/sidhpandit/Desktop/data/nfhs/nfhs1hr/IAHR23FL.DTA"
	
	global ihds1_individual "/Users/sidhpandit/Desktop/data/IHDS/IHDS-1/DS0001/22626-0001-Data.dta"
	
	global ihds1_household "/Users/sidhpandit/Desktop/data/IHDS/IHDS-1/DS0002/22626-0002-Data.dta"
	
	
	global ihds2_individual "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0001/36151-0001-Data.dta"
	
	
	global ihds2_household "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0002/36151-0002-Data.dta"
	
	global ihds2_ewomen "/Users/sidhpandit/Desktop/data/IHDS/IHDS-2/DS0003/36151-0003-Data.dta"
	
	
	global reweighting_dataset "/Users/sidhpandit/Dropbox/maternal nutrition by social group/data/prepared_dataset.dta"
	
	cd "/Users/sidhpandit/Documents/GitHub/nnm-disparities-and-facility-type"
	
	
	global paths "/Users/sidhpandit/Documents/GitHub/nnm-disparities-and-facility-type/dofiles/00 paths.do"
	
	global dataset "/Users/sidhpandit/Library/CloudStorage/Box-Box/Anemia_Thesis/data/nnm dataset.dta"
	
}



if "`c(username)'" == "dc42724" {

	global nfhs5ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IAIR7DDT\IAIR7DFL.DTA"

	global dataset "C:\Users\dc42724\Dropbox\K01\maternal-nutrition-social-group\data\prepared_dataset.dta"
	
	cd "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups"
	
	global paths "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\000_paths.do"
	
	global ihds2_ewomen "C:\Users\dc42724\Dropbox\Data\IHDS\2011 data\women\36151-0003-Data.dta"
}


if "`c(hostname)'" == "PPRC-STATS-P01" {
	
	
	global nfhs3ir "Q:\Coffey\Users\SidhPandit\nfhs3ir\IAIR52FL.dta"
	
	global nfhs3br "Q:\Coffey\Users\SidhPandit\nfhs3br\IABR52FL.dta"
	
	global nfhs5ir "Q:\Coffey\Users\SidhPandit\nfhs5ir\IAIR7EFL.dta"
	
	global nfhs5br "Q:\Coffey\Users\SidhPandit\nfhs5br\IABR7EFL.dta"
	
*	global dataset "C:\Users\dc42724\Dropbox\K01\maternal-nutrition-social-group\data\prepared_dataset.dta"

	
	cd "C:\Users\ssp2843\Documents\GitHub\maternal-nutrition-and-social-groups"
	
	
}




