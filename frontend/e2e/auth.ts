import { createHmac } from 'node:crypto';

const JWT_SECRET = 'mydevsupersecret';

function base64url(data: string | Buffer): string {
	const buf = typeof data === 'string' ? Buffer.from(data) : data;
	return buf.toString('base64url');
}

export function generateTestJWT(claims: {
	sub: string;
	email: string;
	hd: string;
	user_id: number;
	role: string;
}): string {
	const header = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
	const payload = base64url(
		JSON.stringify({
			...claims,
			exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
			iat: Math.floor(Date.now() / 1000)
		})
	);
	const signature = base64url(
		createHmac('sha256', JWT_SECRET).update(`${header}.${payload}`).digest()
	);
	return `${header}.${payload}.${signature}`;
}
