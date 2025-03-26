import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from '@/components/ui/select';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { CheckCircle2 } from 'lucide-react';
import { chains } from '@/config';
import { useTokenInfo } from '@/hooks/useTokenInfo';
import { http, createWalletClient, publicActions } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import {
	publicActionsL2,
	walletActionsL2,
	supersimL2A,
	supersimL2B,
	createInteropSentL2ToL2Messages,
	decodeRelayedL2ToL2Messages,
} from '@eth-optimism/viem';
import { useAccount, useSwitchChain, useWriteContract } from 'wagmi';
import { envVars } from '@/envVars';
import { SuperchainTokenBridgeAbi } from '@/abi/SuperchainTokenBridgeAbi';

type Hash = `0x${string}`;

export const Replay = () => {
	// Account for 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
	const account = privateKeyToAccount(
		'0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
	);

	// Configure clients with optimism extension
	const opChainAClient = createWalletClient({
		transport: http(),
		chain: supersimL2A,
		account,
	})
		.extend(walletActionsL2())
		.extend(publicActionsL2())
		.extend(publicActions);

	const opChainBClient = createWalletClient({
		transport: http(),
		chain: supersimL2B,
		account,
	})
		.extend(walletActionsL2())
		.extend(publicActionsL2())
		.extend(publicActions);

	const { address } = useAccount();
	const { symbol } = useTokenInfo();
	const [hashLog, setHashLog] = useState('');
	const [showAlert, setShowAlert] = useState(false);
	const [sourceChainIdString, setSourceChain] = useState(
		chains[0].id.toString()
	);
	const sourceChainId = parseInt(sourceChainIdString);
	const [targetChainIdString, setTargetChain] = useState(
		chains[1].id.toString()
	);
	const targetChainId = parseInt(targetChainIdString);

	const sourceChain = chains.find((chain) => chain.id === sourceChainId);
	const targetChain = chains.find((chain) => chain.id === targetChainId);

	const { switchChain } = useSwitchChain();

	const { reset } = useWriteContract();

	const handleSourceChainChange = async (chainId: string) => {
		try {
			// Attempt to switch chain first
			await switchChain({ chainId: parseInt(chainId) });

			// Only update the state if chain switch was successful
			setSourceChain(chainId);
			if (chainId === targetChainIdString) {
				const availableChains = chains.filter(
					(chain) => chain.id.toString() !== chainId
				);
				setTargetChain(availableChains[0]?.id.toString() || '');
			}

			reset();
		} catch (error) {
			console.error('Failed to switch chain:', error);
			// Don't update the source chain if switching failed
		}
	};

	const handleSentMessage = async () => {
		const hashString: Hash = hashLog.startsWith('0x')
			? `0x${hashLog.substring(2)}`
			: `0x${hashLog}`;
		let opChainSourceClient, opChainTargetClient;
		if (sourceChainId == 901) {
			console.log(`Relaying message on OPChainB...`);
			opChainSourceClient = opChainAClient;
			opChainTargetClient = opChainBClient;
		} else {
			console.log(`Relaying message on OPChainA...`);
			opChainSourceClient = opChainBClient;
			opChainTargetClient = opChainAClient;
		}
		const sendERC20Receipt =
			await opChainSourceClient.waitForTransactionReceipt({
				hash: hashString,
			});
		const { sentMessages } = await createInteropSentL2ToL2Messages(
			opChainAClient,
			{ receipt: sendERC20Receipt }
		);
		const sentMessage = sentMessages[0];

		const relayTxHash = await opChainTargetClient.relayL2ToL2Message({
			sentMessageId: sentMessage.id,
			sentMessagePayload: sentMessage.payload,
		});

		const relayReceipt = await opChainTargetClient.waitForTransactionReceipt({
			hash: relayTxHash,
		});

		// Ensure the message was relayed successfully

		const { successfulMessages } = decodeRelayedL2ToL2Messages({
			receipt: relayReceipt,
		});
		if (successfulMessages.length != 1) {
			// console.error('failed to relay message!');
			throw new Error('failed to relay message!');
		}
		setShowAlert(true);
	};

	const isButtonDisabled = !address || !sourceChain || !targetChain;

	return (
		<div className='space-y-6'>
			<div>
				<h2 className='text-2xl font-semibold'>Relay {symbol}</h2>
				<p className='text-sm text-muted-foreground'>Replay transaction</p>
				<p className='text-sm text-muted-foreground bg-gray-100 p-4 rounded-md border border-gray-300'>
					<strong>Note:</strong> Use the command:{' '}
					<code className='bg-gray-200 px-1 py-0.5 rounded'>
						cast logs --address 0x4200000000000000000000000000000000000023
						--rpc-url http://127.0.0.1:9545
					</code>{' '}
					to get the Transaction hash from L2ToL2CrossDomainMessenger.
				</p>
			</div>

			<div className='space-y-6'>
				<div className='space-y-4'>
					<div className='space-y-2'>
						<Label>Sent Transaction Hash</Label>
						<Input
							type='text'
							placeholder='0x...'
							value={hashLog}
							onChange={(e) => setHashLog(e.target.value)}
						/>
					</div>

					<div className='grid grid-cols-2 gap-4'>
						<div className='space-y-2'>
							<Label>From Network</Label>
							<Select
								onValueChange={handleSourceChainChange}
								value={sourceChainIdString}
							>
								<SelectTrigger>
									<SelectValue placeholder='Select network' />
								</SelectTrigger>
								<SelectContent>
									{chains.map((chain) => (
										<SelectItem key={chain.id} value={chain.id.toString()}>
											{chain.name}
										</SelectItem>
									))}
								</SelectContent>
							</Select>
						</div>

						<div className='space-y-2'>
							<Label>To Network</Label>
							<Select
								onValueChange={setTargetChain}
								disabled={!sourceChainIdString}
								value={targetChainIdString}
							>
								<SelectTrigger>
									<SelectValue placeholder='Select network' />
								</SelectTrigger>
								<SelectContent>
									{chains
										.filter(
											(chain) => chain.id.toString() !== sourceChainIdString
										)
										.map((chain) => (
											<SelectItem key={chain.id} value={chain.id.toString()}>
												{chain.name}
											</SelectItem>
										))}
								</SelectContent>
							</Select>
						</div>
					</div>
				</div>

				<Button
					className='w-full'
					size='lg'
					disabled={isButtonDisabled}
					onClick={() => {
						handleSentMessage();
					}}
				>
					'Relay'
				</Button>
			</div>
			{showAlert && (
				<Alert
					variant='default'
					className='border-green-500 bg-green-50 dark:bg-green-900/10'
				>
					<CheckCircle2 className='h-4 w-4' color='#22c55e' />
					<AlertTitle className='text-green-500'>Success!</AlertTitle>
					<AlertDescription>
						Successfully replayed SendERC20 message{' '}
						{`0x${hashLog.substring(0, 4)}`}
						on destination chain
						{
							chains.find(
								(chain) => chain.id.toString() === targetChainIdString
							)?.name
						}{' '}
					</AlertDescription>
				</Alert>
			)}
		</div>
	);
};
