Jupyter Notebook Server in a container with some specific Kernels.

Docker image based on [Jupyter-Docker-Stacks](#https://jupyter-docker-stacks.readthedocs.io/en/latest/) minimal-notebook image.
The base image from the Jupyter-Docker-Stacks Project already includes Utilities like PDF-Conversion of Notebooks.  

This image additionally Installs 
* SageMath
* R
* Octave

as Jupyter Kernels.
Also numpy, sympy, scipy are installed via pip.

Start the Container and Jupyter Server within using

      docker run --rm -it -p 127.0.0.1:8888:8888 -v "$HOME/JupyterNotebooks:/home/sage/work:rw" -w /home/sage/work ghcr.io/klrit/jupytermathstackcontainer:main start-notebook.py --PasswordIdentityProvider.hashed_password='argon2:$argon2id$v=19$m=10240,t=10,p=8$JdAN3fe9J45NvK/EPuGCvA$O/tbxglbwRpOFuBNTYrymAEH6370Q2z+eS1eF4GM6Do'

Then open [http://localhost:8888](http://localhost:8888) in your browser

Password is my-password.

change the password it by running

      from jupyter_server.auth import passwd; passwd()
      
inside a notebook code cell (python/sage kernel) and replacing the hashed password string in the above docker run command.
Use a random password and save it in your browser, this password is only for additional security against non-local access.

## License

This repository contains only a Dockerfile and setup instructions.  
All included software and base images remain under their respective original licenses.  
No additional license applies to this repository.
