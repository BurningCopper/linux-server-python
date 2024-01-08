######################################################
# _____                      _              _ _ _   
#|  __ \                    | |            | (_) |  
#| |  | | ___    _ __   ___ | |_    ___  __| |_| |_  
#| |  | |/ _ \  | '_ \ / _ \| __|  / _ \/ _` | | __| 
#| |__| | (_) | | | | | (_) | |_  |  __/ (_| | | |_  
#|_____/ \___/  |_| |_|\___/ \__|  \___|\__,_|_|\__| 
#	 _   _     _        __ _ _      _ 
#	| | | |   (_)      / _(_) |    | |
#	| |_| |__  _ ___  | |_ _| | ___| |
#	| __| '_ \| / __| |  _| | |/ _ \ |
#	| |_| | | | \__ \ | | | | |  __/_|
#	 \__|_| |_|_|___/ |_| |_|_|\___(_)
#
#  User customizations can and will be overwritten at
#  any time, without notice.
#
#  This file is maintained by the HERI network Admin
#  <undetermined>.
#  If changes need to be made, please contact him at
#  support@psychiatry.wisc.edu
#  
#  Users may add customisizations to the user.rc file
#  Type :  nano ~/.$USER.rc  
#  at a command prompt.
#
#  Application based custimizations may be contained
#  in application .rc files.  For example, AFNI
#  options can be chosen in ~/.afnirc.   Please read
#  the fine documentation for more information.
#
######################################################


######################################################
# Global settings
######################################################

# This fixes issues with external programs that incidentally read
# the .bash_profile, such as FileZilla using the SFTP protocol
#
# Essentially, it checks if the current SSH session is interactive
# and, if not, doesn't read the rest of the .bash_profile

[[ ${-#*i} = ${-} ]] && return

# Set umask correctly

umask 002

# Save people from themselves by making rm and mv ask for confirmation
# If using rm/mv in scripts, simply pass the -f option to overwrite

alias rm='rm -i'
alias mv='mv -i'

# Make terminal a bit more pretty

alias ls="ls -AF --color=auto"

######################################################
# Per-system settings
######################################################

case "$HOSTNAME" in

	mri-sterling.heri.psychiatry.wisc.edu | mri-sterling | mri-lana.heri.psychiatry.wisc.edu | mri-lana)
		
		# Initial PATH setup			
		PATH=$PATH:/usr/bin
		PATH=$PATH:/bin
		PATH=$PATH:/usr/sbin
		PATH=$PATH:/sbin
		PATH=$PATH:/usr/local/bin
		PATH=$PATH:/usr/X11/bin
		PATH=$PATH:~/bin
		
		# Fancy terminal colors
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;96m\]\u@\h\[\033[00m\]:\[\033[01;95m\]\w\[\033[00m\]\$ '
		
		# Matlab setup
		PATH=$PATH:/Volumes/apps/linux/matlab-current/bin
		export PATH               

		# FreeSurfer setup
		FREESURFER_HOME=/Volumes/apps/linux/freesurfer-current
		export FREESURFER_HOME
		source $FREESURFER_HOME/SetUpFreeSurfer.sh
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/bin
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/lib
		export PATH        

		# FSL setup
		# FSL requires a command "source ${FSLDIR}/etc/fslconf/fsl.sh".
		# If FSLDIR does not point to the correct resource, it will fail.
		export FSLDIR=/Volumes/apps/linux/fsl-current
		source ${FSLDIR}/etc/fslconf/fsl.sh
		PATH=$PATH:${FSLDIR}/bin
		export PATH

		# AFNI setup
		PATH=$PATH:/Volumes/apps/linux/afni-current
		export PATH

		# Trackvis and Diffusion Toolkit setup                
		PATH=$PATH:/Volumes/apps/linux/trackvis-current
		export PATH
		# This line is needed to avoid X-Windows errors with Trackvis
		export LIBGL_ALWAYS_INDIRECT=1

		# ANTs setup
		ANTSPATH=/Volumes/apps/linux/ants-current/bin
		PATH=$PATH:$ANTSPATH
		export PATH
		
		# set Camino path
		export CAMINO_HEAP_SIZE=32000
		PATH=$PATH:/Volumes/apps/linux/camino-current/bin
		export PATH
		MANPATH=$MANPATH:/Volumes/apps/linux/camino-current/man
		export MANPATH
		
		# Set up DTI-TK  
		# DTITK_ROOT must be declared, or the scripts will not work correctly. 
		DTITK_ROOT=/Volumes/apps/linux/dti-tk-current
		export DTITK_ROOT
		PATH=$PATH:${DTITK_ROOT}/bin
		PATH=$PATH:${DTITK_ROOT}/utilities
		PATH=$PATH:${DTITK_ROOT}/scripts
		export PATH
		
		# Set Cell Ranger alias and path
		PATH=$PATH:/Volumes/apps/linux/cellranger
		export PATH
		
		# Set Integrated Genome Viewer alias
		alias igv="/Volumes/apps/linux/IGV/igv.sh"

		# MRTrix3 setup
        PATH=$PATH:/Volumes/apps/linux/mrtrix-current/bin
        export PATH

		# bowtie2 setup
		PATH=$PATH:/Volumes/apps/linux/bowtie-current/
		export PATH

		;;

	mri-thor.heri.psychiatry.wisc.edu | mri-thor | mri-odin.heri.psychiatry.wisc.edu | mri-odin)

		# Herringa lab processing servers
		
		# Initial PATH setup			
		PATH=$PATH:/usr/bin
		PATH=$PATH:/bin
		PATH=$PATH:/usr/sbin
		PATH=$PATH:/sbin
		PATH=$PATH:/usr/local/bin
		PATH=$PATH:/usr/X11/bin
		PATH=$PATH:~/bin
          
		# Fancy terminal colors
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;96m\]\u@\h\[\033[00m\]:\[\033[01;95m\]\w\[\033[00m\]\$ '  
                
		# Needed for NVIDIA CUDA w/ the Telsa GPUs 
		PATH=$PATH:/usr/local/cuda/bin
		export PATH
		
		# Matlab setup
		PATH=$PATH:/Volumes/apps/linux/matlab-current/bin
		export PATH

		# FreeSurfer setup
		FREESURFER_HOME=/Volumes/apps/linux/freesurfer-current
		export FREESURFER_HOME
		source $FREESURFER_HOME/SetUpFreeSurfer.sh
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/bin
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/lib
		export PATH

		# FSL setup
		# FSL requires a command "source ${FSLDIR}/etc/fslconf/fsl.sh".
		# If FSLDIR does not point to the correct resource, it will fail.
		export FSLDIR=/Volumes/apps/linux/fsl-current
		source ${FSLDIR}/etc/fslconf/fsl.sh
		PATH=$PATH:${FSLDIR}/bin
		export PATH

		# AFNI setup
		PATH=$PATH:/Volumes/apps/linux/afni-current
		export PATH

		# Trackvis and Diffusion Toolkit setup                
		PATH=$PATH:/Volumes/apps/linux/trackvis-current
		export PATH
		# This line is needed to avoid X-Windows errors with Trackvis
		export LIBGL_ALWAYS_INDIRECT=1

		# MRTrix3 setup
		PATH=$PATH:/Volumes/apps/linux/mrtrix-current/bin
		export PATH

		# ANTs setup
		ANTSPATH=/Volumes/apps/linux/ants-current/bin
		PATH=$PATH:$ANTSPATH
		export PATH

		# TORTOISE setup
		PATH=$PATH:/Volumes/apps/linux/tortoise-current/DIFFPREPV314/bin/bin
		PATH=$PATH:/Volumes/apps/linux/tortoise-current/DIFFCALC/DIFFCALCV314
		PATH=$PATH:/Volumes/apps/linux/tortoise-current/DRBUDDIV314/bin
		PATH=$PATH:/Volumes/apps/linux/tortoise-current/DRTAMASV314/bin
		export PATH

		;;
		
	mri-corkin.heri.psychiatry.wisc.edu | mri-corkin | mri-hebb.heri.psychiatry.wisc.edu | mri-hebb)
		
		# Postle lab processing servers
		
		# Initial PATH setup			
		PATH=$PATH:/usr/bin
		PATH=$PATH:/bin
		PATH=$PATH:/usr/sbin
		PATH=$PATH:/sbin
		PATH=$PATH:/usr/local/bin
		PATH=$PATH:/usr/X11/bin
		PATH=$PATH:~/bin
		
		# Fancy terminal colors
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;96m\]\u@\h\[\033[00m\]:\[\033[01;95m\]\w\[\033[00m\]\$ '
		
		# Matlab setup
		PATH=$PATH:/Volumes/apps/linux/matlab-current/bin
		export PATH               

		# FreeSurfer setup
		FREESURFER_HOME=/Volumes/apps/linux/freesurfer-current
		export FREESURFER_HOME
		source $FREESURFER_HOME/SetUpFreeSurfer.sh
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/bin
		PATH=$PATH:/Volumes/apps/linux/freesurfer-current/lib
		export PATH        

		# FSL setup
		# FSL requires a command "source ${FSLDIR}/etc/fslconf/fsl.sh".
		# If FSLDIR does not point to the correct resource, it will fail.
		export FSLDIR=/Volumes/apps/linux/fsl-current
		source ${FSLDIR}/etc/fslconf/fsl.sh
		PATH=$PATH:${FSLDIR}/bin
		export PATH

		# AFNI setup
		PATH=$PATH:/Volumes/apps/linux/afni-current
		export PATH

		# Trackvis and Diffusion Toolkit setup                
		PATH=$PATH:/Volumes/apps/linux/trackvis-current
		export PATH
		# This line is needed to avoid X-Windows errors with Trackvis
		export LIBGL_ALWAYS_INDIRECT=1

		# ANTs setup
		ANTSPATH=/Volumes/apps/linux/ants-current/bin
		PATH=$PATH:$ANTSPATH
		export PATH
		
		# set Camino path
		export CAMINO_HEAP_SIZE=32000
		PATH=$PATH:/Volumes/apps/linux/camino-current/bin
		export PATH
		MANPATH=$MANPATH:/Volumes/apps/linux/camino-current/man
		export MANPATH
		
		# Set up DTI-TK  
		# DTITK_ROOT must be declared, or the scripts will not work correctly. 
		DTITK_ROOT=/Volumes/apps/linux/dti-tk-current
		export DTITK_ROOT
		PATH=$PATH:${DTITK_ROOT}/bin
		PATH=$PATH:${DTITK_ROOT}/utilities
		PATH=$PATH:${DTITK_ROOT}/scripts
		export PATH

		# bowtie2 setup
		PATH=$PATH:/Volumes/apps/linux/bowtie-current/
		export PATH

		;;		
		
esac

# User customizations come last.   
source  ~/.$USER.rc



# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Volumes/conda/deretzlaff/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Volumes/conda/deretzlaff/etc/profile.d/conda.sh" ]; then
        . "/Volumes/conda/deretzlaff/etc/profile.d/conda.sh"
    else
        export PATH="/Volumes/conda/deretzlaff/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

