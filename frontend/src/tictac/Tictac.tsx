import React from 'react';
// import { useAccount, useConnect, useDisconnect } from 'wagmi';

const Tictac: React.FC = () => {
  const truncateAddress = (address: string) => {
    return `${address.slice(0, 8)}...${address.slice(-4)}`
  }
  return (
    <div style={styles.outerContainer}>
      <div style={styles.container}>
        <header style={styles.header}>
          <div style={styles.logo}>
            Tic Tac Toe
          </div>
          <div style={{display: 'flex', flexDirection: 'row', alignItems: 'flex-end'}}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', fontSize: '14px', gap: '4px' }}>
              <span>Chain ID: {'chainId'}</span>
              <span>Address: {'truncateAddress(address!)'}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', flexDirection: 'column', gap: '6px', margin: '0px 10px 2px' }}>
              <button onClick={() => {}} style={styles.disconnectButton}>✕</button>
            </div>
          </div>
        </header>
        <main style={styles.main}>
          <div style={styles.leftContainer}>
            
          </div>
          <div style={styles.rightContainer}>
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%', fontSize: '18px', color: '#666', textAlign: 'center' }}>
              Select a game to play
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Tictac;



const styles = {
  outerContainer: {
    width: '100%',
    height: '100vh',
    backgroundColor: '#f5f5f5',
    display: 'flex',
    justifyContent: 'center',
  },
  container: {
    display: 'flex',
    boxSizing: 'border-box' as const,
    width: '100%',
    height: '100%',
    padding: '30px 5% 60px',
    flexDirection: 'column' as const,
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '10px 0',
    height: '10%'
  },
  main: {
    display: 'flex',
    boxSizing: 'border-box' as const,
    gap: '25px',
    flex: 1,
    paddingTop: '20px',
    height: '90%',
  },
  leftContainer: {
    flex: 1,
    backgroundColor: '#ffffff',
    padding: '25px',
    borderRadius: '20px',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
    overflowY: 'auto' as const,
    minWidth: '175px',
  },
  rightContainer: {
    flex: 4,
    backgroundColor: '#ffffff',
    padding: '20px',
    borderRadius: '20px',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
    overflowY: 'auto' as const,
    minWidth: '470px',
  },
  logo: {
    fontSize: '24px',
    fontWeight: 'bold' as const,
    display: 'flex',
    alignItems: 'center',
  },
  logoIcon: {
    marginRight: '10px',
  },
  chainInfo: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'flex-end',
  },
  disconnectButton: {
    background: 'none',
    border: 'none',
    color: 'black',
    fontSize: '14px',
    cursor: 'pointer',
    padding: '0px',
    margin: '0px',
  },
};

// export default TicTac;

