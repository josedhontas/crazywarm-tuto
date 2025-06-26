#!/bin/bash

# Este script automatiza a instalação do ROS Noetic e do Crazyswarm no Ubuntu.
# Ele verifica se os componentes já estão instalados para pular passos desnecessários.
# Após a instalação/verificação, ele iniciará o crazyswarm_server e abrirá o rviz (GUI)
# em uma sessão tmux para visualização.

echo "--- Iniciando o script completo de instalação e configuração do ROS Noetic e Crazyswarm ---"
echo "AVISO IMPORTANTE: O ROS Noetic chegará ao fim de vida (End-of-Life) em 31 de maio de 2025."
echo "Para novos projetos, é altamente recomendável considerar o uso do ROS 2, que tem suporte contínuo."
echo ""

# --- Parte 1: Instalação Essencial do ROS Noetic ---
echo "--- Parte 1: Verificando e Instalando ROS Noetic ---"

# Verifica se o ROS Noetic já está instalado
if [ -f "/opt/ros/noetic/setup.bash" ]; then
    echo "ROS Noetic já está instalado. Pulando a instalação."
    source /opt/ros/noetic/setup.bash # Garante que o ambiente esteja carregado para os próximos passos
else
    echo "ROS Noetic não encontrado. Iniciando instalação..."

    # Configura o sources.list para ROS
    echo "1. Configurando o sources.list para ROS..."
    sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

    # Configura chaves GPG e atualiza lista de pacotes
    echo "2. Configurando chaves GPG e atualizando pacotes..."
    sudo apt update -y
    sudo apt install -y curl
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    sudo apt update -y

    # Instala o ROS Noetic (Desktop-Full)
    echo "3. Instalando o ROS Noetic Desktop-Full..."
    sudo apt install -y ros-noetic-desktop-full

    # Configura o ambiente ROS
    echo "4. Configurando o ambiente ROS..."
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
    source /opt/ros/noetic/setup.bash # Carrega para a sessão atual

    # Instala dependências de build e inicializa rosdep
    echo "5. Instalando dependências de build e inicializando rosdep..."
    sudo apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
    sudo rosdep init --include-eol-distros || true # Usa '|| true' para não falhar se já inicializado
    rosdep update

    echo "--- Instalação do ROS Noetic concluída! ---"
fi

# --- Parte 2: Instalação e Configuração do Crazyswarm ---
echo ""
echo "--- Parte 2: Verificando e Instalando Crazyswarm ---"

# Verifica se o Crazyswarm já está compilado no workspace
if [ -f "$HOME/ros_ws/devel/setup.bash" ] && [ -d "$HOME/ros_ws/src/crazyswarm" ]; then
    echo "Crazyswarm já parece estar instalado e compilado. Pulando a instalação."
    source "$HOME/ros_ws/devel/setup.bash" # Garante que o ambiente do workspace esteja carregado
else
    echo "Crazyswarm não encontrado ou não compilado. Iniciando instalação..."

    # Clona o repositório do Crazyswarm e configura o workspace
    echo "1. Clonando Crazyswarm e configurando workspace..."
    mkdir -p ~/ros_ws/src
    cd ~/ros_ws/src

    # Remover diretório existente para garantir instalação limpa (útil para re-execuções)
    # [ -d "crazyswarm" ] && rm -rf crazyswarm # Comentado para evitar remoção se a verificação inicial falhar por algum motivo

    git clone https://github.com/USC-ACTLab/crazyswarm.git

    # PASSO CRÍTICO: Inicializa os submódulos Git
    echo "2. Inicializando e atualizando os submódulos Git do Crazyswarm..."
    cd crazyswarm # Entra no diretório do crazyswarm recém-clonado
    git submodule update --init --recursive
    if [ $? -ne 0 ]; then
        echo "ERRO: Falha ao inicializar/atualizar os submódulos Git do Crazyswarm. Verifique sua conexão ou erros de Git."
        exit 1
    fi
    cd ../../ # Volta para ~/ros_ws (raiz do workspace)

    # Retorna para o diretório raiz do workspace para a compilação
    cd ~/ros_ws

    # 3. Instala dependências e compila o Crazyswarm
    echo "3. Instalando dependências e compilando Crazyswarm..."
    rosdep install --from-paths src --ignore-src -r -y
    catkin_make
    if [ $? -ne 0 ]; then
        echo "ERRO: Falha ao compilar o workspace Catkin do Crazyswarm. Verifique as mensagens de erro."
        echo "Pode ser necessário instalar mais dependências específicas do Crazyswarm manualmente."
        exit 1
    fi

    # Configura o ambiente do workspace
    source devel/setup.bash
    echo "source ~/ros_ws/devel/setup.bash" >> ~/.bashrc

    echo "--- Instalação e configuração do Crazyswarm concluídas! ---"
fi

# --- Parte 3: Abrindo a GUI do Crazyswarm (rviz) ---
echo ""
echo "--- Parte 3: Abrindo a GUI do Crazyswarm (rviz) ---"

# Garante que o ambiente esteja configurado para esta sessão, incluindo o workspace do Crazyswarm
# Isso é importante caso o script tenha pulado as instalações e o ambiente não tenha sido 'sourced' ainda.
source ~/.bashrc

# Instala tmux se necessário (para gerenciar processos em segundo plano)
echo "Verificando instalação do tmux..."
sudo apt install -y tmux > /dev/null 2>&1 # Instala silenciosamente
if [ $? -ne 0 ]; then
    echo "AVISO: Falha ao instalar tmux. Não será possível usar sessões tmux para a GUI."
fi

# Inicia o roscore em background, se ainda não estiver rodando
echo "Iniciando roscore em background (se não estiver rodando)..."
if ! pgrep roscore > /dev/null; then
    nohup roscore > /dev/null 2>&1 &
    sleep 5 # Dá um tempo para o roscore subir
    if ! pgrep roscore > /dev/null; then
        echo "ERRO: Falha ao iniciar o roscore. A GUI não poderá ser aberta sem ele. Saindo."
        exit 1
    fi
    echo "Roscore iniciado."
else
    echo "Roscore já está rodando (PID: $(pgrep roscore))."
fi

# Inicia o crazyswarm_server e rviz em uma sessão tmux
echo ""
echo "Iniciando crazyswarm_server e a GUI (rviz) em uma sessão tmux ('crazyswarm_gui_full')..."
echo "Certifique-se de que seus Crazyflies estejam ligados e seu sistema de captura de movimento (se for usar) esteja funcionando."

# Navega para o diretório raiz do workspace para que o roslaunch encontre os arquivos
cd ~/ros_ws

# Cria uma nova sessão tmux para o servidor e rviz
# O `roslaunch crazyswarm hover_swarm.launch` inicia o servidor e, por padrão, o rviz também.
tmux new-session -d -s crazyswarm_gui_full "bash -c 'source ~/ros_ws/devel/setup.bash && roslaunch crazyswarm hover_swarm.launch'"
if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao iniciar o crazyswarm_server e/ou rviz."
    echo "Você pode tentar iniciar manualmente em um novo terminal: source ~/ros_ws/devel/setup.bash && roslaunch crazyswarm hover_swarm.launch"
else
    echo "Servidor e GUI iniciados em segundo plano."
    echo "Dando alguns segundos para os serviços subirem..."
    sleep 10 # Dá um tempo para o servidor e rviz abrirem
fi

echo "--- Processo completo concluído! ---"
echo ""
echo "Para ver a GUI do Crazyswarm (rviz) e o servidor, **conecte-se à sessão tmux**:"
echo "tmux attach-session -t crazyswarm_gui_full"
echo ""
echo "Dentro do tmux:"
echo "  - Você verá a saída do `crazyswarm_server` na primeira janela."
echo "  - Uma nova janela para o `rviz` deve ter aberto automaticamente. Use **'Ctrl+b'** seguido de **'n'** (próxima janela) para ir até ela."
echo "  - Para sair do tmux sem fechar os processos, use **'Ctrl+b'** seguido de **'d'** (detach)."
echo ""
echo "Para rodar um script de voo (como o `hello_world.py`), abra um **NOVO terminal** e execute:"
echo "  source ~/.bashrc"
echo "  cd ~/ros_ws/src/crazyswarm/ros_ws/src/crazyswarm/scripts"
echo "  python3 hello_world.py          # Para hardware real (se o servidor estiver conectado aos CFs)"
echo "  python3 hello_world.py --sim    # Para simulação (mesmo com o servidor rodando, isso usa o modo simulação)"
